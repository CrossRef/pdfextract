require_relative '../spatial'

module PdfExtract
  module Chunks

    # TODO Look for obj[:writing_mode] == :vertical or :horizontal

    Settings.declare :word_slop, {
      :default => 4.0,
      :module => self.name,
      :description => "Maximum allowed space between words for them to be considered part of the same line. word_slop is multiplied by width of the last character in a word to find its joining width."
    }

    def self.select_container containers, chars
      containers.reject { |c| not Spatial.contains? c[:container], chars }.first
    end

    def self.include_in pdf
      deps = [:characters, :headers, :footers, :columns]
      pdf.spatials :chunks, :paged => true, :depends_on => deps do |parser|
        containers = {}

        parser.before do
          containers = {}
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
          
        parser.objects :characters do |chars|
          c = select_container containers, chars
          
          found_chunk = false
          c[:chunks].each do |chunk|
            if Spatial.overlap? :y, :height, chunk, chars
              chunk[:chars] << chars
              chunk[:y] = [chars[:y], chunk[:y]].min                # these are wrong
              chunk[:height] = [chars[:height], chunk[:height]].max # --/
            end
          end

          if not found_chunk
            c[:chunks] << {
              :y => chars[:y],
              :height => chars[:height],
              :chars => [chars]
            }
          end
        end

        parser.after do
          word_slop = pdf.settings[:word_slop]
          chunk_objs = []
          
          containers.each do |container|
            container[:chunks].each do |chunk|
              
              chunk[:chars].sort_by! { |char| char[:x] }

              # merge char content into the first char object
              while chunk[:chars].length > 1
                left = chunk[:chars].first
                right = chunk[:chars][1]

                if left[:x] + left[:width] + (left[:width] * word_slop) <= right[:x]
                  left[:content] += " " + right[:content]
                else
                  left[:content] += right[:content]
                end
                
                left[:width] += right[:width]

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



