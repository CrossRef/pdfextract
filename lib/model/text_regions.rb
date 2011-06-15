
module PdfExtract
  module TextRegions

    # TODO Handle :writing_mode once present in characters and text_chunks.

    def self.incident l, r
      lx1 = l[:x]
      lx2 = l[:x] + l[:width]
      rx1 = r[:x]
      rx2 = r[:x] + r[:width]

      lr = (lx1..lx2)
      rr = (rx1..rx2)

      lr.include? rx1 or lr.include? rx2 or rr.include? lx1 or rr.include? lx2
    end

    def self.concat_lines top, bottom
      if top =~ /\-\Z/
        top + bottom
      else
        top + ' ' + bottom
      end
    end
    
    def self.include_in pdf
      line_slop = 0.7

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

        # TODO Wouldn't handle multiple columns - would leave as lines.
        parser.post do
          line_height = chunks.first[:height]
          while chunks.count > 1
            b = chunks.first
            t = chunks[1]
            
            if ((b[:y] + b[:height] + (line_height * line_slop)) >= t[:y]) and incident(t, b)
              so = SpatialObject.new
              so[:x] = [b[:x], t[:x]].min
              so[:y] = b[:y]
              so[:width] = [b[:width], t[:width]].max
              so[:height] = b[:height] + t[:height]
              so[:content] = concat_lines t[:content], b[:content]
              chunks[0] = so
              chunks.delete_at 1
            else
              # Finished region.
              regions << chunks.first
              chunks.delete_at 0
              line_height = chunks.first[:height]
            end
          end
          regions << chunks.first
          regions
        end
      end
    end
    
  end
end
