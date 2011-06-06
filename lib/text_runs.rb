module TextRuns

  def include_text_runs
    self.spatials :text_runs do |parser|
      global_state = {
        :x => 0,
        :y => 0,
        :width => 0,
        :height => 0,
        :horizontal_scale => 1,
        :char_spacing => 0,
        :word_spacing => 0,
        :leading => 0,
        :rise => 0
      }
      state = global_state

      parser.for :begin_text_object do |data|
        state = global_state.dup
        nil
      end

      parser.for :end_text_object do |data|
        # When not defining a text object, text operators alter a
        # global state.
        state = global_state
        nil
      end

      parser.for :set_text_leading do |data|
        state[:leading] = data
        nil
      end

      parser.for :set_text_rise do |data|
        state[:rise] = data
        nil
      end

      parser.for :set_character_spacing do |data|
        state[:char_spacing] = data
        nil
      end

      parser.for :set_word_spacing do |data|
        state[:word_spacing] = data
        nil
      end

      parser.for :set_horizontal_text_scaling do |data|
        state[:horizontal_scale] = (data.to_f / 100) + 1
        nil
      end

      parser.for :set_text_font_and_size do |data|
        # TODO Examine font ref, in data[0], for width
        # (combine with word spacing, char spacing callback data).

        # TODO Font is defined with height of 1 unit, which is
        # mul by data[1] to get height. However, UserUnit may
        # be specified in the page dictionary, which again should
        # be muled with height, possibly also width.

        # handle writing mode for composite fonts - select
        # one of two sets of font metrics.

        # If glyph displacement vectors are available, 
        # glyph displacement vector needs to be used in conjuction with
        # font height and glyph bounding box / glyph width to determine
        # extent of the run.
        
        # for all but type 3 font, divide all glyph metrics by 1000, for
        # type 3 apply the fontmatrix.

        # Handle type 3 font operators.

        state[:height] = data[1]
        nil
      end
      
      parser.for :show_text_with_positioning do |data|
        so = SpatialObject.new
        so[:x] = compute_x state
        so[:y] = compute_y state
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

      parser.for :move_text_position_and_set_leading do |data|
        state[:x] += data[0]
        state[:y] += data[1]
        state[:leading] = data[2]
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

  private

  def compute_x state
    # TODO Apply graphics matrix, text matrix.
    # TODO units of :rise?
    state[:x] + state[:rise]
  end

  def compute_y state
    # TODO Apply graphics matrix, text matrix.
    # TODO units of :leading?
    state[:y] + state[:leading]
  end

end
