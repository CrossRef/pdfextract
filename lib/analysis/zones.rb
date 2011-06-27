module PdfExtract
  module Zones

    # TODO Headers/footers examine margins. Check header and footer
    # distance from margins. Should be within a factor of the body
    # area.

    def self.include_in pdf
      deps = [:top_margins, :left_margins, :right_margins, :regions]
      pdf.spatials :headers, :paged => true, :depends_on => deps do |parser|
        y_mask = MultiRange.new
        top_margin = nil
        left_margin_x = 0
        right_margin_x = 0

        parser.pre do
          y_mask = MultiRange.new
        end

        parser.objects :left_margins do |lm|
          puts "call left"
          left_margin_x = lm[:x] + lm[:width]
        end

        parser.objects :right_margins do |rm|
          puts "call right"
          right_margin_x = rm[:x]
        end

        parser.objects :top_margins do |m|
          puts "call top"
          top_margin = m
        end

        parser.objects :regions do |r|
          y_mask.append r[:y]..(r[:y] + r[:height])
        end

        parser.post do
          puts "call post"
          if y_mask.count < 2
            nil
          else
            {
              :x => left_margin_x,
              :y => y_mask.max_excluded,
              :width => right_margin_x - left_margin_x,
              :height => top_margin[:y] - y_mask.max_excluded,
              :page => top_margin[:page],
              :page_width => top_margin[:page_width],
              :page_height => top_margin[:page_height]
            }
          end
        end
      end

      pdf.spatials :footers do |parser|
      end

      pdf.spatials :bodies do |parser|
      end
    end

  end
end
