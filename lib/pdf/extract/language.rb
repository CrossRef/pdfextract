require_relative 'names.rb'

module PdfExtract::Language

  def self.transliterate s
    r = ""

    s.each_char do |c|
      case c

      # Remove ligatures
      when "\ufb00" then r << "ff"
      when "\ufb01" then r << "fi"
      when "\ufb02" then r << "fl"
      when "\ufb03" then r << "ffi"
      when "\ufb04" then r << "ffl"
      when "\ufb05" then r << "ft"
      when "\ufb06" then r << "st"
      when "\u1d6b" then r << "ue"

      # Normalise some punctuation.
      when "\u2018" then r << "'"
      when "\u2019" then r << "'"
      when "\u2013" then r << "-"
      when "\u2014" then r << "-"
      when "\u201c" then r << "\""
      when "\u201d" then r << "\""
      when "\u25af" then r << "("
      when "\u00b4" then r << ""
      when "\u00b1" then r << "-"

      else
        r << c
      end
    end

    r.gsub /\s+/, " "
  end

  def self.letter_ratio s
    s.count("A-Z0-9\-[],.\"'()") / s.length.to_f
  end

  # TODO Ignore caps in middle of words
  def self.cap_ratio s
    sentence_end = true
    cap_count = 0

    s.each_char do |c|
      if c =~ /\./
        sentence_end = true
      elsif c =~ /[A-Z]/
        cap_count = cap_count + 1 unless sentence_end
        sentence_end = false
      elsif c =~ /[^\s]/
        sentence_end = false
      end
    end

    cap_count / s.split.length.to_f
  end

  def self.year_ratio s
    words = s.split

    year_words = words.map do |word|
      word =~ /[^\d]\d{4}[^\d]/
    end

    year_words.reject { |year_word| not year_word }.length / words.length.to_f
  end

  def self.name_ratio content
    PdfExtract::Names.detect_names(content)[:name_frequency]
  end

  def self.word_count s
    s.split.count
  end

end

