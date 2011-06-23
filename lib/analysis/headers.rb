require_relative '../multi_range'

module PdfExtract
  module Headers

    def self.include_in pdf
      pdf.spatials :headers, :paged => true, :depends_on => [:regions] do |parser|
        y_mask = MultiRange.new
        page = -1
        page_width = 0
        page_height = 0

        parser.pre do
          y_mask = MultiRange.new
          page = -1
        end

        parser.objects :regions do |region|
          if page == -1
            page = region[:page]
            page_width = region[:page_width]
            page_height = region[:page_height]
          end
          y_mask.append region[:y]..(region[:y]+region[:height])
        end

        parser.post do
          if y_mask.count < 2
            nil
          else
            {
              :x => 0,
              :y => y_mask.max_excluded,
              :width => page_width,
              :height => page_height - y_mask.max_excluded,
              :page => page,
              :page_width => page_width,
              :page_height => page_height
            }
          end
        end
        
      end
    end

  end
end
