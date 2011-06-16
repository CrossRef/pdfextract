module PdfExtract
  module Language

    def self.transliterate s
      s = s.gsub "\ufb01", "fi"
      s = s.gsub "\ufb02", "fl"
      s = s.gsub "\u2018", "'"
      s = s.gsub "\u2019", "'"
      s
    end

  end
end
