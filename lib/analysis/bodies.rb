
module PdfExtract
  module Bodies

    def self.include_in pdf
      pdf.spatials :bodies, :depends_on => [:regions] do |parser|
        
        font_frequencies = {}
        regions = []
        bodies = []
        
        parser.objects :regions do |region|
          name = region[:font].to_s + "_" + region[:line_height].floor.to_s
          font_frequencies[name] ||= 0
          font_frequencies[name] += region[:content].length
          regions << region
        end

        parser.post do
          top_font = font_frequencies.to_a.sort_by { |f| f[1] }.reverse.first
          font, size = top_font[0].split "_"
          regions.each do |region|
            if region[:font].to_s == font &&
                region[:line_height].floor.to_s == size &&
                region[:height] > region[:line_height]
              bodies << region.dup
            end
          end
          bodies
        end
      end
    end

  end
end
