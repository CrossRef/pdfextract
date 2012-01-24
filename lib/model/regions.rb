require_relative '../spatial'

module PdfExtract
  module Regions

    Settings.declare :min_region_spacing, {
      :default => 0.5,
      :module => self.name,
      :description => "A minimum spacing between chunks, over which chunks form separate regions."
    }

    # TODO Handle :writing_mode once present in characters and text_chunks.

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

    def self.select_container containers, chars
      containers.reject { |c|
        not Spatial.contains? c[:container], chars
      }.first
    end
    
    def self.include_in pdf
      deps = [:chunks, :columns, :headers, :footers]
      pdf.spatials :regions, :paged => true, :depends_on => deps do |parser|
        containers = []

        parser.before do
          containers = []
        end

        parser.objects :headers do |header|
          containers << {
            :container => header,
            :chunks => [],
            :regions => []
          }
        end

        parser.objects :footers do |footer|
          containers << {
            :container => footer,
            :chunks => [],
            :regions => []
          }
        end

        parser.objects :columns do |column|
          containers << {
            :container => column,
            :chunks => [],
            :regions => []
          }
        end
        
        parser.objects :chunks do |chunk|
          c = select_container containers, chunk
          if not c.nil?
            chunk[:lines] = [Spatial.as_line(chunk)]
            chunk.delete :content
            c[:chunks] << chunk
          end
        end

        # TODO Rewrite to use Spatial::collapse so that text is in proper
        # order.

        parser.after do
          min_region_spacing = pdf.settings[:min_region_spacing]
          regions = []

          # Join chunks into regions unless there is a wide gap
          # between chunks.
          containers.each do |container|
            container[:chunks].sort_by! { |chunk| -chunk[:y] }
            last_chunk = nil

            container[:chunks].each do |chunk|
              if last_chunk.nil?
                container[:regions] << chunk
              elsif chunk[:y] + chunk[:height] + (min_region_spacing * chunk[:line_height]) >= last_chunk[:y]
                container[:regions][-1] = Spatial.merge container[:regions].last, chunk, :lines => true
              else
                container[:regions] << chunk
              end
              last_chunk = chunk
            end
          end

          all_regions = containers.map {|c| c[:regions] }.flatten

          # Add line offset and line spacing information to regions.
          all_regions.each do |region|
            append_line_offsets region
            append_line_spacing region

            region[:lines].map! do |line|
              Spatial.drop_spatial line
            end
          end
        end
      end
    end
    
  end
end
