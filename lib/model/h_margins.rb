module PdfExtract
  module HorizontalMargins

    def self.include_in pdf
      pdf.spatials :h_margins, :depends_on => [:text_regions] do |parser|
        regions = []
        parser.objects :text_regions do |region|
          regions << region
        end

        parser.post do
          margins = []
        end
      end
    end

  end
end
