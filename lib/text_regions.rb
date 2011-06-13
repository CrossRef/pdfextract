
module PdfExtract
  module TextRegions

    # TODO Handle :writing_mode once present in characters and text_chunks.
    
    def self.include_in pdf
      line_slop = 0.3

      pdf.spatials :text_regions, :depends_on => [:text_chunks] do |parser|
        chunks = []
        parser.objects :text_chunks do |text_chunk|
          chunks << text_chunk
        end
        
        parser.post do
          chunks.sort_by! { |obj| obj[:y] }

          while chunks.length > 1
            top = chunks.first
            bottom = chunks[1]
            
          end
        end
      end
    end

  end
end
