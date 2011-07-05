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

    def self.word_count s
      s.split(/\s/).count
    end

  end
end
