module PdfExtract
  module Util
    
    def self.singular_name name
      name.sub /s$/, ''
    end

  end
end
