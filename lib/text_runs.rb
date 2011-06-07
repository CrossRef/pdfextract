module PdfExtract

  module TextRuns

    def self.glyph_width c, state
      # TODO Find glyph width in font.
      # TODO Honour font operators that have changed state
      0
    end

    def self.glyph_displacement c, state
      # TODO Determine writing mode
      # TODO Pick correct displacement values
      [0, 0]
    end

    def self.make_text_runs text, state
      # TODO Apply text matrix
      # TODO Apply CTM
      # TODO Ignore chars outside the page :MediaBox?
      # TODO Determine where & when to recent text matrix.
      # TODO Mul UserUnit if specified by page.
      # TODO If :char_space is 0 use font glyph width?
      # TODO If :word_space is 0, check for word space in font def.
      # TODO Include writing mode, so that runs can be joined either
      #      virtically or horizontally in the join stage.
      
      objs = []

      x = state.last[:x] - (state.last[:tj] / 1000.0)
      y = state.last[:y] + state.last[:rise]
      h_scale_mod = (1 + (state.last[:horizontal_scale] / 100.0))
      total_displacement_x = 0
      total_displacement_y = 0
      
      text.split(//).each do |c|
        so = SpatialObject.new
        so[:x] = x + total_displacement_x
        so[:y] = y + total_displacement_y
        so[:width] = glyph_width(c, state) * h_scale_mod
        so[:height] = state.last[:height]
        so[:content] = c

        dx, dy = glyph_displacement c, state
        total_displacement_x += dx
        total_displacement_y += dy
        
        objs << so
      end

      objs
    end

    def self.include_in pdf

      pdf.spatials :text_runs do |parser|
        state = []
        page = nil

        parser.for :begin_page do |data|
          page = data
          state << {
            :horizontal_scale => 100,
            :char_spacing => 0,
            :word_spacing => 0,
            :leading => 0,
            :rise => 0,
            :a => 1,
            :b => 0,
            :c => 0,
            :d => 1,
            :e => 0,
            :f => 0,
            :font => nil,
            :x => 0,
            :y => 0,
            :width => 0,
            :height => 0,
            :tj => 0
          }
          nil
        end

        parser.for :begin_text_object do |data|
          state.push state.last.dup
          nil
        end

        parser.for :end_text_object do |data|
          # When not defining a text object, text operators alter a
          # global state.
          state.pop
          nil
        end

        # State change operators.

        parser.for :set_text_leading do |data|
          state.last[:leading] = data
          nil
        end

        parser.for :set_text_rise do |data|
          state.last[:rise] = data
          nil
        end

        parser.for :set_character_spacing do |data|
          state.last[:char_spacing] = data
          nil
        end

        parser.for :set_word_spacing do |data|
          state.last[:word_spacing] = data
          nil
        end

        parser.for :set_horizontal_text_scaling do |data|
          state.last[:horizontal_scale] = data
          nil
        end

        # Position change operators.

        parser.for :move_text_position do |data|
          state.last[:x] += data[0]
          state.last[:y] += data[1]
          nil
        end

        parser.for :move_text_position_and_set_leading do |data|
          state.last[:x] += data[0]
          state.last[:y] += data[1]
          state.last[:leading] = data[1]
          nil
        end

        # Font change operators.

        parser.for :set_text_font_and_size do |data|
          # TODO set state.last[:font] to font object.
          state.last[:height] = data[1]
          nil
        end

        # Text matrix change operators.

        parser.for :set_text_matrix_and_text_line_matrix do |data|
          # --     --
          # | a b 0 |
          # | c d 0 |
          # | e f 1 |
          # --     --
          state.last[:a] = data[0]
          state.last[:b] = data[1]
          state.last[:c] = data[2]
          state.last[:d] = data[3]
          state.last[:e] = data[4]
          state.last[:f] = data[5]
          nil
        end

        # New line operators.

        parser.for :move_to_start_of_next_line do |data|
          state.last[:y] += state.last[:leading]
          nil
        end

        # Show text operators.

        parser.for :set_spacing_next_line_show_text do |data|
          state.last[:word_spacing] = data[0]
          state.last[:char_spacing] = data[1]
          state.last[:y] += state.last[:leading]

          make_text_runs data[2], state
        end

        parser.for :move_to_next_line_and_show_text do |data|
          state.last[:y] += state.last[:leading]

          make_text_runs data.first, state
        end

        parser.for :show_text do |data|
          make_text_runs data.first, state
        end
        
        parser.for :show_text_with_positioning do |data|
          data = data.first # TODO Handle elsewhere.
          runs = []
          state.push state.last.dup # Record :tj
          
          data.each do |item|
            case item.class.to_s
            when "Fixnum", "Float"
              state.last[:tj] = item
            when "String"
              runs << make_text_runs(item, state)
            end
          end

          state.pop # Restore :tj
          runs.flatten
        end
        
      end
    end

  end

end
