require_relative '../spatial'

module PdfExtract
  module Regions

    Settings.declare :line_slop, {
      :default => 1.0,
      :module => self.name,
      :description => "Maximum allowed line spacing between lines that are considered
to be part of the same region. :line_slop is multiplied by the average line height of a region to find a maximum line spacing between a region and a candidate line."
    }

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

    def self.append_line_offsets region
      region[:lines] ||= []
      region[:lines].each do |line|
        line[:x_offset] = line[:x] - region[:x]
        line[:y_offset] = line[:y] - region[:y]
      end
    end

    def self.append_line_spacing region
      region[:lines] ||= []
      height_taken = 0
      region[:lines].each do |line|
        from_top = region[:height] - (line[:y_offset] + line[:height])
        line[:spacing] = from_top - height_taken
        height_taken = from_top + line[:height]
      end
    end

    def self.include_in pdf
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
          # Convert chunks to have line content.
          chunks.each do |chunk|
            chunk[:lines] = [Spatial.as_line(chunk)]
            chunk.delete :content
          end

          compare_index = 1
          while chunks.count > compare_index
            b = chunks.first
            t = chunks[compare_index]

            line_height = b[:line_height]
            line_slop = [line_height, t[:height]].min * pdf.settings[:line_slop]
            incident_y = (b[:y] + b[:height] + line_slop) >= t[:y]

            if incident_y && incident(t, b)
              chunks[0] = Spatial.merge t, b, :lines => true
              chunks.delete_at compare_index
              compare_index = 1
            elsif compare_index < chunks.count - 1
              # Could be more chunks within range.
              compare_index = compare_index.next
            else
              # Finished region.
              regions << chunks.first
              chunks.delete_at 0
              compare_index = 1
            end
          end

          regions << chunks.first unless chunks.first.nil?

          regions.each do |region|
            append_line_offsets region
            append_line_spacing region

            region[:lines].map! do |line|
              Spatial.drop_spatial line
            end
          end

          regions.sort_by { |obj| -obj[:y] }
        end
      end
    end

  end
end
