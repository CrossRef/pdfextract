require_relative '../spatial'

module PdfExtract
  module Chunks

    # TODO Look for obj[:writing_mode] == :vertical or :horizontal

    Settings.declare :min_word_spacing, {
      :default => 0.01,
      :module => self.name,
      :description => "Minimum distance between characters, as a factor of character width, for characters to be cosidered as belonging to separate words."
    }

    def self.select_container containers, chars
      containers.reject { |c|
        not Spatial.contains? c[:container], chars
      }.first
    end

    def self.include_in pdf
      deps = [:characters, :headers, :footers, :columns]
      pdf.spatials :chunks, :paged => true, :depends_on => deps do |parser|
        containers = []

        parser.before do
          containers = []
        end

        parser.objects :headers do |header|
          containers << {
            :container => header,
            :chunks => []
          }
        end

        parser.objects :footers do |footer|
          containers << {
            :container => footer,
            :chunks => []
          }
        end

        parser.objects :columns do |column|
          containers << {
            :container => column,
            :chunks => []
          }
        end
          
        parser.objects :characters do |char|
          c = select_container containers, char

          if not c.nil?
            found_chunk = false
            c[:chunks].each do |chunk|
              if Spatial.overlap? :y, :height, chunk, char
                chunk[:chars] << char
                chunk[:y] = [char[:y], chunk[:y]].min                
                chunk[:height] = [char[:height], chunk[:height]].max # this is wrong
                found_chunk = true
                break
              end
            end
            
            if not found_chunk
              c[:chunks] << {
                :y => char[:y],
                :height => char[:height],
                :chars => [char]
              }
            end
          end
        end

        parser.after do
          min_word_spacing = pdf.settings[:min_word_spacing]
          chunk_objs = []
          
          containers.each do |container|
            container[:chunks].each do |chunk|
              
              chunk[:chars].sort_by! { |char| char[:x] }

              # merge char content into the first char object
              while chunk[:chars].length > 1
                
                left = chunk[:chars].first
                right = chunk[:chars][1]

                if left[:x] + left[:width] + (left[:width] * min_word_spacing) <= right[:x]
                  left[:content] += " " + right[:content]
                else
                  left[:content] += right[:content]
                end
                
                left[:width] = (right[:x] + right[:width]) - left[:x]

                chunk[:chars].delete_at 1
              end

              # make a chunk object out of the first char object and
              # chunk data
              chunk_objs << chunk[:chars].first.merge({
                :y => chunk[:y],
                :height => chunk[:height]
              })

            end
          end

          chunk_objs
        end
      end
    end

  end
end



