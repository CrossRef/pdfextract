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

    Settings.declare :zone_slop, {
      :default => 4,
      :module => "Bodies, Headers, Footers",
      :description => "Vertical slop applied to characters when calculating an x-axis mask used to determine header and footer locations."
    }

    def self.include_in pdf
      deps = [:top_margins, :left_margins, :right_margins, :bottom_margins, :characters]
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
          from = c[:y] #- pdf.settings[:zone_slop]
          to = c[:y] + c[:height] #+ pdf.settings[:zone_slop]
          y_mask.append from..to
        end

        parser.after do
          # TODO Ignore header and/or footer if gap is too small
          # TODO Would benefit from masking out images and tables
          
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
            :height => footer_gap.min
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
