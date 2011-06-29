module PdfExtract
  module Columns

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
          # TODO Rewrite to allow configurable number of check lines.
          quarter = columns_at(body[:y] + (body[:height] * 0.25), body_regions)
          half = columns_at(body[:y] + (body[:height] * 0.5), body_regions)
          three_quarter = columns_at(body[:y] + (body[:height] * 0.75), body_regions)

          # TODO Want highest count, then that with the widest column(s).
          most = [quarter, half, three_quarter].max { |r| r.count }

          most.ranges.map do |range|
            body.merge({:x => range.min, :width => range.max - range.min })
          end
        end
        
      end
    end

  end
end
