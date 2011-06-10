
module PdfExtract
  module TextChunks

    def self.include_in pdf
      char_slop = 0.2
      word_slop = 1.0
      line_slop = 0.3
      
      pdf.spatials :text_chunks, :depends_on => [:characters] do |parser|
        y_sorted_text = []
        parser.objects :characters do |chars|
          y_sorted_text << chars
        end
        parser.post do
          y_sorted_text.sort_by! { |obj| obj[:y] }
          while y_sorted_text.length > 0
            y = y_sorted_text.first[:y]
            row = y_sorted_text.take_while { |obj| obj[:y] == y }
            y_sorted_text = y_sorted_text.drop_while { |obj| obj[:y] == y }
            row.sort_by! { |obj| obj[:x] }

            while row.length > 1
              left = row.first
              right = row[1]

              if (left[:x] + left[:width] + (left[:width] * char_slop)) <= right[:x]
                # join as adjacent chars
              elsif (left[:x] + left[:width] + (left[:width] * word_slop)) <= right[:x]
                # join with a ' ' in the middle.
              else
                # leave 'em be.
              end
            end
          end
        end 
      end
    end

  end
end
