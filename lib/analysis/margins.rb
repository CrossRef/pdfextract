require_relative '../multi_range'

module PdfExtract
  module Margins

    def self.axis_spatials pdf, name, axis
      pdf.spatials name, :paged => true, :depends_on => [:characters] do |parser|
        axis_mask = MultiRange.new
        page = -1
        page_width = 0
        page_height = 0

        dimension = :width if axis == :x
        dimension = :height if axis == :y

        parser.before do
          axis_mask = MultiRange.new
          page = -1
        end

        parser.objects :characters do |character|
          if page == -1
            page = character[:page]
            page_width = character[:page_width]
            page_height = character[:page_height]
          end
          
          axis_mask.append character[axis]..(character[axis]+character[dimension])
        end

        parser.after do
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

    def self.include_in pdf
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
