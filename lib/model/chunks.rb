require_relative '../spatial'

module PdfExtract
  module Chunks

    # TODO Look for obj[:writing_mode] == :vertical or :horizontal

    Settings.default :char_slop, 0.2
    Settings.default :word_slop, 4.0
    Settings.default :overlap_slop, 0.9

    def self.include_in pdf
      char_slop = 0.2
      word_slop = 4.0
      overlap_slop = 0.9
      
      pdf.spatials :chunks, :paged => true, :depends_on => [:characters] do |parser|
        rows = {}

        parser.before do
          rows = {}
        end
        
        parser.objects :characters do |chars|
          y = chars[:y]
          rows[y] = [] if rows[y].nil?

          idx = rows[y].index { |obj| chars[:x] <= obj[:x] }
          if idx.nil?
            rows[y] << chars.dup
          else
            rows[y].insert idx, chars.dup
          end
        end

        parser.after do
          char_slop = pdf.settings[:char_slop]
          word_slop = pdf.settings[:word_slop]
          overlap_slop = pdf.settings[:overlap_slop]
          
          text_chunks = []

          rows.each_pair do |y, row|
            char_width = row.first[:width]

            while row.length > 1
              left = row.first
              right = row[1]

              if (left[:x] + left[:width] + (char_width * char_slop)) >= right[:x]
                # join as adjacent chars
                row[0] = Spatial.merge left, right
                row.delete_at 1
                char_width = right[:width] unless right[:content].strip =~ /[^A-Za-z0-9]/
              elsif (left[:x] + left[:width] + (char_width * word_slop)) >= right[:x]
                # join with a ' ' in the middle.
                row[0] = Spatial.merge left, right, :separator => ' '
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

            if overlap >= overlap_slop
              # TODO follow char / word slop rules.
              # join
              text_chunks[0] = Spatial.merge left, right
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

