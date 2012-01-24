module PdfExtract
  module Zones

    def self.include_in pdf
      deps = [:top_margins, :left_margins, :right_margins,
              :bottom_margins, :characters, :images]
      pdf.spatials :zones, :paged => true, :depends_on => deps do |parser|
        y_mask = MultiRange.new
        t_margin = nil
        b_margin = nil
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
          t_margin = m
        end

        parser.objects :bottom_margins do |m|
          b_margin = m
        end

        parser.objects :characters do |c|
          y_mask.append (c[:y] .. (c[:y] + c[:height]))
        end

        parser.objects :images do |i|
          y_mask.append (i[:y] .. (i[:y] + i[:height]))
        end

        parser.after do
          # TODO Ignore header and/or footer if gap is too small
          # TODO case where body does not extend to near bottom of page?

          page_bottom =  b_margin[:y] + b_margin[:height]
          page_height = t_margin[:y] - page_bottom
          page_top = page_bottom + page_height

          footer_search = page_bottom .. (page_bottom + (page_height * 0.2))
          header_search = (page_top - (page_height * 0.2)) .. page_top

          footer_gap = y_mask.intersection(footer_search).widest_gap
          header_gap = y_mask.intersection(header_search).widest_gap

          objs = []

          objs << {
            :group => :footers,
            :x => left_margin_x,
            :y => b_margin[:y] + b_margin[:height],
            :width => right_margin_x - left_margin_x,
            :height => footer_gap.min - (b_margin[:y] + b_margin[:height])
          }

          objs << {
            :group => :bodies,
            :x => left_margin_x,
            :y => footer_gap.max,
            :width => right_margin_x - left_margin_x,
            :height => header_gap.min - footer_gap.max
          }

          objs << {
            :group => :headers,
            :x => left_margin_x,
            :y => header_gap.max,
            :width => right_margin_x - left_margin_x,
            :height => t_margin[:y] - header_gap.max
          }

          page_base = {
            :page => t_margin[:page],
            :page_width => t_margin[:page_width],
            :page_height => t_margin[:page_height]
          }
          
          objs.map { |o| page_base.merge o }
        end
      end

      pdf.spatials :headers, :depends_on => [:zones]
      pdf.spatials :footers, :depends_on => [:zones]
      pdf.spatials :bodies, :depends_on => [:zones]
    end

  end
end
