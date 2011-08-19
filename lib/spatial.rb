
module PdfExtract
  module Spatial

    @@default_options = {
      :separator => '',
      :lines => false,
      :write_mode => :left_to_right
    }

    @@spatial_attribs = [:x, :y, :width, :height, :page_width, :page_height, :page]

    def self.concat_lines top, bottom
      if top =~ /\-\Z/
        top[0..-2] + bottom
      else
        top + ' ' + bottom
      end
    end

    def self.drop_spatial obj
      obj.dup.delete_if { |k, v| @@spatial_attribs.include? k }
    end

    def self.merge_lines a, b, so
      so[:lines] = []
      
      if a.key? :lines
        so[:lines] += a[:lines]
      else
        so[:lines] << {:content => a[:content], :x => a[:x]}
      end
      
      if b.key? :lines
        so[:lines] += b[:lines]
      else
        so[:lines] << {:content => b[:content], :x => b[:x]}
      end

      so
    end

    def self.merge a, b, options={}
      options = @@default_options.merge options

      bottom_left = [ [a[:x], b[:x]].min, [a[:y], b[:y]].min ]
      top_right = [ [a[:x] + a[:width], b[:x] + b[:width]].max,
                    [a[:y] + a[:height], b[:y] + b[:height]].max ]

      so = a.merge(b).merge({
        :x => bottom_left[0],
        :y => bottom_left[1],
        :width => top_right[0] - bottom_left[0],
        :height => top_right[1] - bottom_left[1]
      })

      if options[:lines]
        merge_lines a, b, so
      else
        so[:content] = a[:content] + options[:separator] + b[:content]
      end
      
      if a[:content].length > b[:content].length
        so[:font] = a[:font]
        so[:line_height] = a[:line_height]
      else
        so[:font] = b[:font]
        so[:line_height] = b[:line_height]
      end

      so
    end

    def self.get_text_content obj
      if obj[:lines]
        obj[:lines].map { |l| l[:content] }.join "\n"
      elsif obj[:content]
        obj[:content]
      else
        obj
      end
    end

    # Collapse a list of objects into one. Will merge objects in the
    # correct write order, specified by write_mode.
    def self.collapse objs, options={}
      options = @@default_options.merge options
      
      sorted = case write_mode
               when :left_to_right
                 objs.sort_by { |obj| -(obj[:y].floor * 100) + (obj[:x] / 100.0) }
               end
      
      if sorted.count == 1
        sorted.first.dup
      else
        o = sorted.delete_at(0).dup
        while not sorted.count.zero?
          merge o, sorted.delete_at(0)
        end
        o
      end
    end

    def self.contains? a, b
      a_x1 = a[:x]
      a_x2 = a[:x] + a[:width]
      a_y1 = a[:y]
      a_y2 = a[:y] + a[:height]

      b_x1 = b[:x]
      b_x2 = b[:x] + b[:width]
      b_y1 = b[:y]
      b_y2 = b[:y] + b[:height]

      b_x1 >= a_x1 && b_x2 <= a_x2 && b_y1 >= a_y1 && b_y2 <= a_y2 
    end
    
  end
end
