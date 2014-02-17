module PdfExtract
  module Zones

    # TODO Headers/footers examine margins. Check header and footer
    # distance from margins. Should be within a factor of the body
    # area.

    Settings.declare :body_ratio, {
      :default => 0.9,
      :module => "Bodies, Headers, Footers",
      :description => "Minium permitted ratio of page height to candidate body zone height. When detecting headers, footers and body (area between header and footer) zones, candidate header and footer areas will be disregarded if they imply a body area whose height to page height ratio is less than :body_ratio."
    }

    def self.include_in pdf
      deps = [:top_margins, :left_margins, :right_margins, :bottom_margins, :regions]
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

        parser.objects :regions do |r|
          y_mask.append r[:y]..(r[:y] + r[:height])
        end

        parser.after do
          # Mask out a middle chunk of the document.
          marginless_height = t_margin[:y] - (b_margin[:y] + b_margin[:height])
          a = (marginless_height - (marginless_height * pdf.settings[:body_ratio])) / 2
          y_mask.append((b_margin[:y] + b_margin[:height] + a)..(t_margin[:y] - a))
          
          objs = []
          
          if y_mask.count < 2
            objs << {
              :group => :bodies,
              :x => left_margin_x,
              :y => b_margin[:y] + b_margin[:height],
              :width => right_margin_x - left_margin_x,
              :height => t_margin[:y] - (b_margin[:y] + b_margin[:height])
            }
          elsif y_mask.count < 3
            top = {
              :x => left_margin_x,
              :y => y_mask.max_excluded,
              :width => right_margin_x - left_margin_x,
              :height => t_margin[:y] - y_mask.max_excluded
            }

            bottom = {
              :x => left_margin_x,
              :y => b_margin[:y] + b_margin[:height],
              :width => right_margin_x - left_margin_x,
              :height => top[:y] - (b_margin[:y] + b_margin[:height])
            }

            if top[:height] > bottom[:height]
              top[:group] = :bodies
              bottom[:group] = :footers
            else
              top[:group] = :headers
              bottom[:group] = :bodies
            end

            objs += [top, bottom]
          else
            header = {
              :group => :headers,
              :x => left_margin_x,
              :y => y_mask.max_excluded,
              :width => right_margin_x - left_margin_x,
              :height => t_margin[:y] - y_mask.max_excluded
            }

            footer = {
              :group => :footers,
              :x => left_margin_x,
              :y => b_margin[:y] + b_margin[:height],
              :width => right_margin_x - left_margin_x,
              :height => y_mask.min_excluded - (b_margin[:y] + b_margin[:height])
            }

            body = {
              :group => :bodies,
              :x => left_margin_x,
              :y => footer[:y] + footer[:height],
              :width => right_margin_x - left_margin_x,
              :height => header[:y] - (footer[:y] + footer[:height])
            }

            objs += [header, body, footer]
          end

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
