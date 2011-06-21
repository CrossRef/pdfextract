
module PdfExtract
  module Spatial

    def self.concat_lines top, bottom
      if top =~ /\-\Z/
        top[0..-2] + bottom
      else
        top + ' ' + bottom
      end
    end

    def self.merge left, right, options={:separator => '', :lines => false}
      bottom_left = [ [left[:x], right[:x]].min, [left[:y], right[:y]].min ]
      top_right = [ [left[:x] + left[:width], right[:x] + right[:width]].max,
                    [left[:y] + left[:height], right[:y] + right[:height]].max ]

      so = left.merge(right).merge({
        :x => bottom_left[0],
        :y => bottom_left[1],
        :width => top_right[0] - bottom_left[0],
        :height => top_right[1] - bottom_left[1]
      })

      if options[:lines]
        so[:content] = concat_lines left[:content], right[:content]
      else
        so[:content] = left[:content] + options[:separator] + right[:content]
      end
      
      if left[:content].length > right[:content].length
        so[:font] = left[:font]
        so[:line_height] = left[:line_height]
      else
        so[:font] = right[:font]
        so[:line_height] = right[:line_height]
      end

      so
    end

  end
end
