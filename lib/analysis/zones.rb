require_relative '../multi_range'

module PdfExtract
  module Zones

    def self.axis_spatials pdf, name, axis
      pdf.spatials name, :paged => true, :depends_on => [:regions] do |parser|
        axis_mask = MultiRange.new
        page = -1
        page_width = 0
        page_height = 0

        dimension = :width if axis == :x
        dimension = :height if axis == :y

        parser.pre do
          axis_mask = MultiRange.new
          page = -1
        end

        parser.objects :regions do |region|
          if page == -1
            page = region[:page]
            page_width = region[:page_width]
            page_height = region[:page_height]
          end
          
          # XXX Some characters are generated with a negative width.
          unless region[dimension] <= 0
            axis_mask.append region[axis]..(region[axis]+region[dimension])
          end
        end

        parser.post do
          if axis_mask.count.zero?
            nil
          else
            yield axis_mask, {
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
      axis_spatials pdf, :headers, :y do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => y_mask.max_excluded,
          :width => obj[:page_width],
          :height => obj[:page_height] - y_mask.max_excluded
        })
      end

      axis_spatials pdf, :footers, :y do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => 0,
          :width => obj[:page_width],
          :height => y_mask.min_excluded
        })
      end

      axis_spatials pdf, :top_margins, :y do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => y_mask.max,
          :width => obj[:page_width],
          :height => obj[:page_height] - y_mask.max
        })
      end

      axis_spatials pdf, :bottom_margins, :y do |y_mask, obj|
        obj.merge({
          :x => 0,
          :y => 0,
          :width => obj[:page_width],
          :height => y_mask.min
        })
      end

      axis_spatials pdf, :left_margins, :x do |x_mask, obj|
        obj.merge({
          :x => 0,
          :y => 0,
          :width => x_mask.min,
          :height => obj[:page_height]
        })
      end

      axis_spatials pdf, :right_margins, :x do |x_mask, obj|
        obj.merge({
          :x => x_mask.max,
          :y => 0,
          :width => obj[:page_width] - x_mask.max,
          :height => obj[:page_height]
        })
      end
    end

  end
end
