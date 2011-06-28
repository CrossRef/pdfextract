require_relative '../spatial'

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
    
    def self.include_in pdf
      line_slop_factor = 0.3

      pdf.spatials :regions, :paged => true, :depends_on => [:chunks] do |parser|
        chunks = []
        regions = []

        parser.before do
          chunks = []
          regions = []
        end
        
        parser.objects :chunks do |chunk|
          y = chunk[:y].floor

          idx = chunks.index { |obj| chunk[:y] <= obj[:y] }
          if idx.nil?
            chunks << chunk.dup
          else
            chunks.insert idx, chunk.dup
          end
        end

        # TODO Rewrite to use Spatial::collapse so that text is in proper
        # order.
        
        parser.after do
          compare_index = 1
          while chunks.count > compare_index
            b = chunks.first
            t = chunks[compare_index]

            line_height = b[:line_height]
            line_slop = [line_height, t[:height]].min * line_slop_factor
            incident_y = (b[:y] + b[:height] + line_slop) >= t[:y]
            
            if incident_y && incident(t, b)
              chunks[0] = Spatial.merge t, b, :lines => true
              chunks.delete_at compare_index
              compare_index = 1
            elsif incident_y
              # Could be more chunks within range on y axis.
              compare_index = compare_index.next
            else
              # Finished region.
              regions << chunks.first
              chunks.delete_at 0
              compare_index = 1
            end
          end
          regions << chunks.first
        end
      end
    end
    
  end
end
