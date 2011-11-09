require_relative "names"

module PdfExtract::Language

  def self.transliterate s
    s = s.gsub "\ufb01", "fi"
    s = s.gsub "\ufb02", "fl"
    s = s.gsub "\ufb03", "ffi"
    s = s.gsub "\ufb04", "ffl"
    s = s.gsub "\ufb06", "st"
    s = s.gsub "\u2018", "'"
    s = s.gsub "\u2019", "'"
    s = s.gsub "\u2013", "-"
    s = s.gsub "\u2014", "-"
    s = s.gsub "\u201c", "\""
    s = s.gsub "\u201d", "\""
    s = s.gsub "\u25af", "("
    s = s.gsub "\u00b4", ""
    s = s.gsub "\u00b1", "-"
    

    s = s.gsub /\s+/, " "
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

