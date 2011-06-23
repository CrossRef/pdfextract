require_relative '../multi_range'

module PdfExtract
  module Zones

    def self.axis_spatials pdf, name
      pdf.spatials name, :paged => true, :depends_on => [:regions] do |parser|
        y_mask = MultiRange.new
        page = -1
        page_width = 0
        page_height = 0

        parser.pre do
          y_mask = MultiRange.new
          page = -1
        end

        parser.objects :regions do |region|
          if page == -1
            page = region[:page]
            page_width = region[:page_width]
            page_height = region[:page_height]
          end
          y_mask.append region[:y]..(region[:y]+region[:height])
        end

        parser.post do
          if y_mask.count < 2
            nil
          else
            yield y_mask, {
              :page => page,
              :page_width => page_width,
              :page_height => page_height
            }
          end
        end
      end
    end

    # TODO Headers/footers examine margins. Check header and footer
    # distance from margins. Should be within a factor of the body
    # area.

    def self.include_in pdf
      axis_spatials pdf, :headers do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => y_mask.max_excluded,
          :width => obj[:page_width],
          :height => obj[:page_height] - y_mask.max_excluded
        })
      end

      axis_spatials pdf, :footers do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => 0,
          :width => obj[:page_width],
          :height => y_mask.min_excluded
        })
      end

      axis_spatials pdf, :middles do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => y_mask.min_excluded,
          :width => obj[:page_width],
          :height => y_mask.max_excluded - y_mask.min_excluded
        })
      end

      axis_spatials pdf, :top_margins do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => y_mask.max,
          :width => obj[:page_width],
          :height => obj[:page_height] - y_mask.max
        })
      end

      axis_spatials pdf, :bottom_margins do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => 0,
          :width => obj[:page_width],
          :height => y_mask.min
        })
      end
    end

  end
end
