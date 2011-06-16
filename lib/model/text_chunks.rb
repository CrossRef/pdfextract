
module PdfExtract
  module TextChunks

    # TODO Look for obj[:writing_mode] == :vertical or :horizontal

    def self.include_in pdf
      char_slop = 0.2
      word_slop = 1.5
      vertical_overlap_factor = 0.9
      
      pdf.spatials :text_chunks, :depends_on => [:characters] do |parser|
        rows = {}
        parser.objects :characters do |chars|
          # TODO Handle pages.
          y = chars[:y]
          rows[y] = [] if rows[y].nil?

          idx = rows[y].index { |obj| chars[:x] <= obj[:x] }
          if idx.nil?
            rows[y] << chars.dup
          else
            rows[y].insert idx, chars.dup
          end
        end

        parser.post do
          text_chunks = []

          rows.each_pair do |y, row|
            char_width = row.first[:width]

            while row.length > 1
              left = row.first
              right = row[1]

              if (left[:x] + left[:width] + (char_width * char_slop)) >= right[:x]
                # join as adjacent chars
                so = SpatialObject.new
                so[:content] = left[:content] + right[:content]
                so[:x] = left[:x]
                so[:y] = left[:y]
                so[:width] = (right[:x] - left[:x]) + right[:width]
                so[:height] = [left[:height], right[:height]].max
                row[0] = so
                row.delete_at 1
                char_width = right[:width] unless right[:content].strip =~ /[^A-Za-z0-9]/
              elsif (left[:x] + left[:width] + (char_width * word_slop)) >= right[:x]
                # join with a ' ' in the middle.
                so = SpatialObject.new
                so[:content] = left[:content] + ' ' + right[:content]
                so[:x] = left[:x]
                so[:y] = left[:y]
                so[:width] = (right[:x] - left[:x]) + right[:width]
                so[:height] = [left[:height], right[:height]].max
                row[0] = so
                row.delete_at 1
                char_width = right[:width] unless right[:content].strip =~ /[^A-Za-z0-9]/
              else
                # leave 'em be.
                text_chunks << left
                row.delete_at 0
                char_width = row.first[:width]
              end
            end

            text_chunks << row.first
          end

          # Merge chunks that have slightly different :y positions but which
          # mostly overlap in the y dimension.

          text_chunks.sort_by! { |obj| obj[:x] }
          merged_text_chunks = []

          while text_chunks.count > 1
            left = text_chunks.first
            right = text_chunks[1]

            overlap = [left[:height], right[:height]].min - (left[:y] - right[:y]).abs
            overlap = overlap / [left[:height], right[:height]].min

            if overlap >= vertical_overlap_factor
              # join
              so = SpatialObject.new
              so[:x] = left[:x]
              so[:y] = left[:y]
              so[:width] = (right[:x] - left[:x]) + right[:width]
              so[:height] = [left[:height], right[:height]].max
              so[:content] = left[:content] + right[:content]

              text_chunks[0] = so
              text_chunks.delete_at 1
            else
              # no join
              merged_text_chunks << text_chunks.first
              text_chunks.delete_at 0
            end
          end
          
          merged_text_chunks << text_chunks.first
        end 
      end
    end

  end
end
