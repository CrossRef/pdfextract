
module PdfExtract
  module TextRegions

    # TODO Handle :writing_mode once present in characters and text_chunks.

    def self.incident l, r
      (l[:x] >= r[:x] and l[:x] + l[:width] <= r[:x] + r[:width]) or (r[:x] >= l[:x] and r[:x] + r[:width] <= l[:x] + l[:width])
    end
    
    def self.include_in pdf
      line_slop = 0.4

      pdf.spatials :text_regions, :depends_on => [:text_chunks] do |parser|
        chunks = []
        regions = []
        
        parser.objects :text_chunks do |text_chunk|
          y = text_chunk[:y].floor

          idx = chunks.index { |obj| text_chunk[:y] <= obj[:y] }
          if idx.nil?
            chunks << text_chunk.dup
          else
            chunks.insert idx, text_chunk.dup
          end
        end

        parser.post do
          while chunks.count > 1
            b = chunks.first
            t = chunks[1]
            
            if ((b[:y] + b[:height] + (b[:height] * line_slop)) >= t[:y]) and incident(t, b)
              so = SpatialObject.new
              so[:x] = [b[:x], t[:x]].min
              so[:y] = b[:y]
              so[:width] = [b[:width], t[:width]].max
              so[:height] = b[:height] + t[:height]
              so[:content] = t[:content] + "\n" + b[:content]
              chunks[0] = so
              chunks.delete_at 1
            else
              regions << chunks.first
              chunks.delete_at 0
            end
          end
          regions << chunks.first
          regions
        end
      end
    end
    
  end
end
