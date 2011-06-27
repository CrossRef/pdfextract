module PdfExtract
  module Zones

    # TODO Headers/footers examine margins. Check header and footer
    # distance from margins. Should be within a factor of the body
    # area.

    def self.include_in pdf
      deps = [:top_margins, :left_margins, :right_margins, :bottom_margins, :regions]
      pdf.spatials :zones, :paged => true, :depends_on => deps do |parser|
        y_mask = MultiRange.new
        top_margin = nil
        bottom_margin = nil
        left_margin_x = 0
        right_margin_x = 0

        parser.before do
          y_mask = MultiRange.new
        end

        parser.objects :left_margins do |lm|
          left_margin_x = lm[:x] + lm[:width]
        end

        parser.objects :right_margins do |rm|
          right_margin_x = rm[:x]
        end

        parser.objects :top_margins do |m|
          top_margin = m
        end

        parser.objects :bottom_margins do |m|
          bottom_margin = m
        end

        parser.objects :regions do |r|
          y_mask.append r[:y]..(r[:y] + r[:height])
        end

        parser.after do
          page_base = {
            :page => top_margin[:page],
            :page_width => top_margin[:page_width],
            :page_height => top_margin[:page_height]
          }
          
          header = page_base.merge({
            :group => :headers,
            :x => left_margin_x,
            :y => y_mask.max_excluded,
            :width => right_margin_x - left_margin_x,
            :height => top_margin[:y] - y_mask.max_excluded,
          })

          footer = page_base.merge({
            :group => :footers,
            :x => left_margin_x,
            :y => bottom_margin[:y],
            :width => right_margin_x - left_margin_x,
            :height => y_mask.min_excluded - (bottom_margin[:y] + bottom_margin[:height])
          })

          body = page_base.merge({
            :group => :bodies,
            :x => left_margin_x,
            :y => footer[:y] + footer[:height],
            :width => right_margin_x - left_margin_x,
            :height => header[:y] - (footer[:y] + footer[:height])
          })

          # TODO Depending on heights, would want [header, body] or [body, footer],
          # where body may be the top mask if mask is big enough.
          
          if y_mask.count < 2
            body
          elsif y_mask.count < 3
            [header, body]
          else
            [header, body, footer]
          end
        end
      end

      pdf.spatials :headers, :depends_on => [:zones]
      pdf.spatials :footers, :depends_on => [:zones]
      pdf.spatials :bodies, :depends_on => [:zones]
    end

  end
end
