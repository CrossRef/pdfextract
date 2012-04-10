require_relative '../spatial'

module PdfExtract
  module Chunks

    # TODO Look for obj[:writing_mode] == :vertical or :horizontal

    Settings.declare :char_slop, {
      :default => 0.2,
      :module => self.name,
      :description => "Maximum allowed space between characters for them to be considered part of the same word. char_slop is multiplied by the width of each character to find its joining width."
    }

    Settings.declare :word_slop, {
      :default => 4.0,
      :module => self.name,
      :description => "Maximum allowed space between words for them to be considered part of the same line. word_slop is multiplied by width of the last character in a word to find its joining width."
    }

    Settings.declare :overlap_slop, {
      :default => 0.9,
      :module => self.name,
      :description => "A minimum permitted ratio of the overlapped height of words for them to join together into lines."
    }

    def self.include_in pdf

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

          # Remove empty lines - they mess up region detection by
          # making them join together.
          merged_text_chunks.reject { |chunk| chunk[:content].strip == "" }
        end
      end
    end

  end
end

