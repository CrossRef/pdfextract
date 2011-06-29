module PdfExtract
  module Columns

    @@column_sample_count = 3

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
          step = 1.0 / (@@column_sample_count + 1)
          column_ranges = []

          (1 .. @@column_sample_count).each do |i|
            y = body[:y] + (body[:height] * i * step)
            column_ranges << columns_at(y, body_regions)
          end
          
          # Discard those with more than four columns. They've probably hit a table.
          column_ranges.reject! { |r| r.count > 4 }
          
          # TODO Want highest count, then that with the widest column(s).
          most = column_ranges.max { |r| r.count }

          most.ranges.map do |range|
            body.merge({:x => range.min, :width => range.max - range.min })
          end
        end
        
      end
    end

  end
end
