
module PdfExtract
  module Regions

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
        top[0..-2] + bottom
      else
        top + ' ' + bottom
      end
    end
    
    def self.include_in pdf
      line_slop_factor = 0.3

      pdf.spatials :regions, :depends_on => [:chunks] do |parser|
        chunks = []
        regions = []
        
        parser.objects :chunks do |text_chunk|
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
          while chunks.count > 1
            b = chunks.first
            t = chunks[1]

            line_height = b[:line_height] || b[:height]
            line_slop = [line_height, t[:height]].min * line_slop_factor
            
            if ((b[:y] + b[:height] + line_slop) >= t[:y]) && incident(t, b)
              so = SpatialObject.new
              so[:x] = [b[:x], t[:x]].min
              so[:y] = b[:y]
              so[:width] = [b[:width], t[:width]].max
              so[:height] = (t[:y] - b[:y]) + t[:height]
              so[:content] = concat_lines t[:content], b[:content]
              so[:line_height] = line_height
              chunks[0] = so
              chunks.delete_at 1
            else
              # Finished region.
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
