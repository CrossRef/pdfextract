module PdfExtract
  module Language

    def self.transliterate s
      s = s.gsub "\ufb01", "fi"
      s = s.gsub "\ufb02", "fl"
      s = s.gsub "\u2018", "'"
      s = s.gsub "\u2019", "'"
      s = s.gsub "\u2013", "-"
      s = s.gsub "\u201c", "\""
      s = s.gsub "\u201d", "\""
      s
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
        word =~ /\.*\d{4}\.*/
      end

      year_words.reject { |year_word| not year_word }.length / words.length.to_f
    end

    def self.word_count s
      s.split.count
    end
    
  end
end
