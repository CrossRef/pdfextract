
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
        so[:lines] << as_line(a)
      end

      if b.key? :lines
        so[:lines] += b[:lines]
      else
        so[:lines] << as_line(b)
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
        so[:content] = (a[:content] + options[:separator] + b[:content])
        so[:content] = so[:content].gsub /\s+/, " "
      end

      if get_text_content(a).length > get_text_content(b).length
        so[:font] = a[:font]
        so[:line_height] = a[:line_height]
      else
        so[:font] = b[:font]
        so[:line_height] = b[:line_height]
      end

      so
    end

    def self.line_count obj
      line_count = 0
      line_count += obj[:content].count("\n") + 1 if obj[:content]
      line_count += obj[:lines].length if obj[:lines]
      line_count
    end

    def self.get_dimensions obj
      {
        :x => obj[:x],
        :y => obj[:y],
        :width => obj[:width],
        :height => obj[:height],
        :page => obj[:page],
        :page_width => obj[:page_width],
        :page_height => obj[:page_height]
      }
    end

    def self.as_line obj
      get_dimensions(obj).merge({:content => obj[:content]})
    end

    def self.get_text_content obj
      if obj[:lines]
        obj[:lines].map do |line|
          if line[:content] =~ /\-\Z/
            line[:content][0..-2]
          else
            line[:content] + " "
          end
        end.join("").strip
      elsif obj[:content]
        obj[:content]
      else
        ""
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

    def self.contains? a, b, padding=0
      a_x1 = a[:x] - padding
      a_x2 = a[:x] + a[:width] + (padding * 2)
      a_y1 = a[:y] - padding
      a_y2 = a[:y] + a[:height] + (padding * 2)

      b_x1 = b[:x]
      b_x2 = b[:x] + b[:width]
      b_y1 = b[:y]
      b_y2 = b[:y] + b[:height]

      b_x1 >= a_x1 && b_x2 <= a_x2 && b_y1 >= a_y1 && b_y2 <= a_y2
    end

    def self.overlap? from, by, a, b
      a_top = a[from] + a[by]
      b_top = b[rom] + b[by]

      (b_top <= a_top && b_top >= a[from]) || (b[from] >= a[from] && b[from] <= b_top)
    end

    def self.score items, ideals, name
      ideals.keys.each do |f|
        diffs = items.map {|item| (item[f] - ideals[f][0]).abs}
        diffs.map! {|d| d.nan? ? 1 : d}
        max_diff = diffs.max

        scores = diffs.map do |d|
          if d == 0
            ideals[f][1]
          else
            (1 - (d / max_diff)) * ideals[f][1]
          end
        end

        items.each_index do |i|
          items[i][name] ||= 0
          items[i][name] = items[i][name] + scores[i]
        end
      end
    end

  end
end
