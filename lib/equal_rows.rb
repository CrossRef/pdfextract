require_relative "multi_range"
require_relative "spatial"

module PdfExtract

  class EqualRows

    def initialize region, row_count
      @rows = []

      row_height = region[:height] / row_count.to_f
      current_y = 0.0
      
      row_count.times do
        @rows << {
          :x => region[:x],
          :y => current_y,
          :width => region[:width],
          :height => row_height,
          :column_mask => MultiRange.new
        }
        current_y = current_y + row_height
      end
    end

    def append obj
      @rows.each do |row|
        if Spatial.contains? row, obj
          row[:column_mask].append obj[:x]..(obj[:x]+obj[:width])
        end
      end
    end
    
  end

end
