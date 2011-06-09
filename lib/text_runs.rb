require 'matrix'

module PdfExtract

  module TextRuns

    # TODO Implement for Type3 fonts (They may have :WMode 0 or 1),
    # and :FontMatrix.

    def self.glyph_descent c, state
      # For non-Type3, use :Descent from the font descriptor.
      if state.last[:font].nil? or state.last[:font].descent.nil?
        0
      else
        state.last[:font].descent / 1000.0
      end
    end

    def self.glyph_ascent c, state
      # For non-Type3, use :Ascent from the font descriptor.
      if state.last[:font].nil? or state.last[:font].ascent.nil?
        0
      else
        state.last[:font].ascent / 1000.0
      end
    end
    
    def self.glyph_width c, state
      # For non-Type3 fonts, :Widths may be used to determine glyph width.
      # This is the same as vertical displacemnt.
      glyph_displacement(c, state)[0]
    end

    def self.glyph_height c, state
      # For non-Type3 fonts, :Ascent and :Descent from the :FontDescriptor
      # can be used to determine maximum glyph height.
      glyph_ascent(c, state) - glyph_descent(c, state)
    end

    def self.glyph_displacement c, state
      # For non-Type3 fonts, vertical displacement is the glyph width,
      # horizontal displacement is always 0. Note glyph width is given
      # in 1000ths of text units.
      if state.last[:font].nil?
        # XXX Why are some font resources not reported via resource_font?
        # Bug in pdf-reader?
        [ 0, 0 ]
      else
        [ state.last[:font].glyph_width(c) / 1000.0, 0 ]
      end
    end

    def self.make_text_runs text, state, graphics_state
      # TODO Ignore chars outside the page :MediaBox.
      # TODO Mul UserUnit if specified by page.
      # TODO Include writing mode, so that runs can be joined either
      #      virtically or horizontally in the join stage.

      state.push state.last.dup # Record :tm
      
      objs = []
      h_scale_mod = (1 + (state.last[:h_scale] / 100.0))
      
      text.split(//).each do |c|
        s = state.last
        
        trm = Matrix[ [s[:font_size] * h_scale_mod, 0, 0],
                      [0, s[:font_size], 0],
                      [0, s[:rise], 1] ]
        trm = trm * s[:tm] * graphics_state.last[:ctm]
        
        so = SpatialObject.new
        so[:x] = trm.row(2)[0]
        so[:y] = trm.row(2)[1] + (glyph_descent(c, state) * s[:font_size])
        so[:width] = glyph_width(c, state) * h_scale_mod * s[:font_size]
        so[:height] = glyph_height(c, state) * s[:font_size]
        so[:content] = c
        objs << so
        
        disp_x, disp_y = glyph_displacement(c, state)
        spacing = s[:char_spacing] if c != ' '
        spacing = s[:word_spacing] if c == ' '
        tx = ((disp_x - (s[:tj] / 1000.0)) * s[:font_size] + spacing) * h_scale_mod
        ty = (disp_y - (s[:tj] / 1000.0)) * s[:font_size] + spacing
              
        s[:tm] = s[:tm] * Matrix[ [1, 0, 0], [0, 1, 0], [tx, 0, 1] ]
        # TODO Above should use either tx or ty depending on writing mode.
      end
      
      state.pop # Restore :tm

      objs
    end

    def self.include_in pdf

      pdf.spatials :text_runs do |parser|
        state = []
        graphics_state = []
        page = nil
        fonts = {}

        parser.for :resource_font do |data|
          fonts[data[0]] = data[1]
          nil
        end

        parser.for :begin_page do |data|
          page = data
          state << {
            :tm => Matrix.identity(3),
            :h_scale => 0,
            :char_spacing => 0,
            :word_spacing => 0,
            :leading => 0,
            :rise => 0,
            :font => nil,
            :tj => 0,
            :font_size => 0
          }
          graphics_state << {
            :ctm => Matrix.identity(3)
          }
          nil
        end

        # Graphics state operators.

        # TODO Handle gs graphics state operation.

        parser.for :save_graphics_state do |data|
          graphics_state.push graphics_state.last.dup
          nil
        end

        parser.for :restore_graphics_state do |data|
          graphics_state.pop
          nil
        end

        parser.for :concatenate_matrix do |data|
          a, b, c, d, e, f = data
          ctm = graphics_state.last[:ctm]
          graphics_state.last[:ctm] = ctm * Matrix[ [a, b, 0], [c, d, 0], [e, f, 1] ]
          nil
        end

        # Start/end text object operators.

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
          state.last[:leading] = data.first
          nil
        end

        parser.for :set_text_rise do |data|
          state.last[:rise] = data.first
          nil
        end

        parser.for :set_character_spacing do |data|
          state.last[:char_spacing] = data.first
          nil
        end

        parser.for :set_word_spacing do |data|
          state.last[:word_spacing] = data.first
          nil
        end

        parser.for :set_horizontal_text_scaling do |data|
          state.last[:h_scale] = data.first
          nil
        end

        # Position change operators.

        parser.for :move_text_position do |data|
          state.last[:tm] = state.last[:tm] * Matrix[
            [1, 0, 0], [0, 1, 0], [data[0], data[1], 1]
          ]
          nil
        end

        parser.for :move_text_position_and_set_leading do |data|
          state.last[:tm] = state.last[:tm] * Matrix[
            [1, 0, 0], [0, 1, 0], [data[0], data[1], 1]
          ]
          state.last[:leading] = -data[1]
          nil
        end

        # Font change operators.

        parser.for :set_text_font_and_size do |data|
          state.last[:font] = fonts[data[0]]
          state.last[:font_size] = data[1]
          nil
        end

        # Text matrix change operators.

        parser.for :set_text_matrix_and_text_line_matrix do |data|
          # --     --
          # | a b 0 |
          # | c d 0 |
          # | e f 1 |
          # --     --
          a, b, c, d, e, f = data
          state.last[:tm] = Matrix[ [a, b, 0], [c, d, 0], [e, f, 1] ]
          nil
        end

        # New line operators.

        parser.for :move_to_start_of_next_line do |data|
          state.last[:tm] = state.last[:tm] * Matrix[
            [1, 0, 0], [0, 1, 0], [0, -state.last[:leading], 1]
          ]
          nil
        end

        # Show text operators.

        parser.for :set_spacing_next_line_show_text do |data|
          state.last[:word_spacing] = data[0]
          state.last[:char_spacing] = data[1]
          
          state.last[:tm] = state.last[:tm] * Matrix[
            [1, 0, 0], [0, 1, 0], [0, -state.last[:leading], 1]
          ]

          make_text_runs data[2], state, graphics_state
        end

        parser.for :move_to_next_line_and_show_text do |data|
          state.last[:tm] = state.last[:tm] * Matrix[
            [1, 0, 0], [0, 1, 0], [0, -state.last[:leading], 1]
          ]

          make_text_runs data.first, state
        end

        parser.for :show_text do |data|
          make_text_runs data.first, state, graphics_state
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
              runs << make_text_runs(item, state, graphics_state)
            end
          end

          state.pop # Restore :tj
          runs.flatten
        end
        
      end
    end

  end

end
