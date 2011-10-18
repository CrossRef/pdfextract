module PdfExtract
  module Columns

    Settings.default :column_sample_count, 8
    Settings.default :body_width_factor, 0.75

    def self.columns_at y, body_regions
      x_mask = MultiRange.new

      body_regions.each do |region|
        if region[:y] <= y && (region[:y] + region[:height]) >= y
          x_mask.append(region[:x] .. (region[:x] + region[:width]))
        end
      end

      x_mask
    end

    def self.include_in pdf
      deps = [:regions, :bodies]
      pdf.spatials :columns, :paged => true, :depends_on => deps do |parser|
        
        body = nil
        body_regions = []

        parser.before do
          body_regions = []
        end
        
        parser.objects :bodies do |b|
          body = b
        end

        parser.objects :regions do |region|
          if Spatial.contains? body, region
            body_regions << region
          end
        end

        parser.after do
          body_width_factor = pdf.settings[:body_width_factor]
          column_sample_count = pdf.settings[:column_sample_count]
          
          step = 1.0 / (column_sample_count + 1)
          column_ranges = []

          (1 .. column_sample_count).each do |i|
            y = body[:y] + (body[:height] * i * step)
            column_ranges << columns_at(y, body_regions)
          end

          # Disard those whose columns represent less than @@body_width_factor
          # of the body width.
          column_ranges.reject! { |r| r.covered < (body[:width] * body_width_factor) }
          
          # Discard those with more than four columns. They've probably hit a table.
          column_ranges.reject! { |r| r.count > 4 }

          if column_ranges.count.zero?
            []
          else
            # Find the highest column count.
            most = column_ranges.max_by { |r| r.count }.count
            column_ranges.reject! { |r| r.count != most }

            # Take the columns that are widest.
            widest = column_ranges.map { |r| r.avg }.max
            column_ranges.reject! { |r| r.avg < widest }

            column_ranges.first.ranges.map do |range|
              body.merge({:x => range.min, :width => range.max - range.min })
            end
          end
        end
        
      end
    end

  end
end
