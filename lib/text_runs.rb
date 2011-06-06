module TextRuns

  def include_text_runs
    self.spatials :text_runs do |parser|
      clean_state = {
        :x => 0,
        :y => 0,
        :width => 0,
        :height => 0,
        :horizontal_scale => 1
      }

      state = clean_state.dup

      parser.for :end_text_object do |data|
        state = clean_state.dup
        nil
      end

      parser.for :set_text_font_and_size do |data|
        # TODO Examine font ref, in data[0], for width
        # (combine with word spacing, char spacing callback data).

        # TODO Modify height by set_text_rise callback data.

        # TODO Font is defined with height of 1 unit, which is
        # mul by data[1] to get height. However, UserUnit may
        # be specified in the page dictionary, which again should
        # be muled with height, possibly also width.

        state[:height] = data[1]
        nil
      end

      parser.for :set_horizontal_text_scaling do |data|
        state[:horizontal_scale] = (data.to_f / 100) + 1
        nil
      end
      
      parser.for :show_text_with_positioning do |data|
        so = SpatialObject.new
        so[:x] = state[:x]
        so[:y] = state[:y]
        so[:width] = 0 # TODO sum_char_widths state, data
        so[:height] = state[:height]
        so[:content] = data
        so
      end

      parser.for :move_text_position do |data|
        state[:x] += data[0]
        state[:y] += data[1]
        nil
      end

      # TODO According to pdf-reader example, need to handle:
      # :show_text_with_positioning
      # :show_text
      # :super_show_text
      # :move_to_next_line_and_show_text
      # :set_spacing_next_line_show_text
      
      # TODO Add state modifiers for other text positioning
      # callbacks.
    end
  end

end
