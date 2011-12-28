require 'matrix'

require_relative '../font_metrics'

module PdfExtract
  module Characters

    # TODO Implement writing mode and :FontMatrix.

    def self.glyph_descent c, state
      if state.last[:font_metrics].nil? || state.last[:font_metrics].descent.nil?
        0
      else
        state.last[:font_metrics].descent / 1000.0
      end
    end

    def self.glyph_ascent c, state
      if state.last[:font_metrics].nil? || state.last[:font_metrics].ascent.nil?
        0
      else
        state.last[:font_metrics].ascent / 1000.0
      end
    end
    
    def self.glyph_width c, state
      # :Widths may be used to determine glyph width. This is the same as
      # horizontal displacemnt.
      glyph_displacement(c, state)[0]
    end

    def self.glyph_height c, state
      # :Ascent and :Descent from the :FontDescriptor can be used to determine
      # maximum glyph height.
      glyph_ascent(c, state) - glyph_descent(c, state)
    end

    def self.glyph_displacement c, state
      # For non-Type3 fonts, vertical displacement is the glyph width,
      # horizontal displacement is always 0. Note glyph width is given
      # in 1000ths of text units.
      if state.last[:font_metrics].nil?
        # XXX Why are some font resources not reported via resource_font?
        # Bug in pdf-reader? Possibly because of :Font entry in graphics
        # state set.
        [ 0, 0 ]
      else
        [ state.last[:font_metrics].glyph_width(c) / 1000.0, 0 ]
      end
    end

    def self.find_media_box page, objects
      if page[:MediaBox]
        page[:MediaBox]
      elsif page[:Parent]
        find_media_box objects[page[:Parent]], objects
      else
        [0, 0, 0, 0]
      end
    end

    def self.make_text_runs text, tj, state, render_state, page, page_number
      # TODO Mul UserUnit if specified by page.
      # TODO Include writing mode, so that runs can be joined either
      #      virtically or horizontally in the join stage.
      
      objs = []
      h_scale_mod = (state.last[:h_scale] / 100.0)
      s = state.last
      
      disp_x, disp_y = [0, 0]
      spacing = 0
      tx = ((disp_x - (tj / 1000.0)) * s[:font_size] + spacing) * h_scale_mod
      ty = (disp_y - (tj / 1000.0)) * s[:font_size] + spacing

      # TODO Should use either tx or ty depending on writing mode.
      render_state[:tm] = Matrix[ [1, 0, 0], [0, 1, 0], [tx, 0, 1] ] * render_state[:tm]

      # tj applies only to the first char of the Tj op.
      tj = 0
      
      text.each_char do |c|
        trm = Matrix[ [s[:font_size] * h_scale_mod, 0, 0],
                      [0, s[:font_size], 0],
                      [0, s[:rise], 1] ]
        trm = trm * render_state[:tm] * state.last[:ctm]

        bl_pos = Matrix.rows( [ [0, glyph_descent(c, state), 1] ])
        bl_pos = bl_pos * trm

        width = glyph_width(c, state)
        height = glyph_descent(c, state) + glyph_height(c, state)

        tr_pos = Matrix.rows([ [width, height, 1] ])
        tr_pos = tr_pos * trm

        px = bl_pos.row(0)[0]
        py = bl_pos.row(0)[1]

        media_box = find_media_box(page.page_object, page.objects)
        
        objs << {
          :x => px,
          :y => py,
          :width => tr_pos.row(0)[0] - px,
          :height => tr_pos.row(0)[1] - py,
          :line_height => tr_pos.row(0)[1] - py,
          :content => state.last[:font].to_utf8(c),
          :page => page_number,
          :font => state.last[:font].basefont,
          :page_width => media_box[2] - media_box[0],
          :page_height => media_box[3] - media_box[1]
        }
        
        disp_x, disp_y = glyph_displacement(c, state)
        spacing = s[:char_spacing] if c != ' '
        spacing = s[:word_spacing] if c == ' '
        tx = ((disp_x - (tj / 1000.0)) * s[:font_size] + spacing) * h_scale_mod
        ty = (disp_y - (tj / 1000.0)) * s[:font_size] + spacing

        # TODO Should use either tx or ty depending on writing mode.
        render_state[:tm] = Matrix[ [1, 0, 0], [0, 1, 0], [tx, 0, 1] ] * render_state[:tm]
      end
      
      objs
    end

    def self.build_fonts page
      fonts = {}
      font_metrics = {}
      page.fonts.each do |label, font_obj|
        font = PDF::Reader::Font.new(page.objects, font_obj)
        fonts[label] = font
        font_metrics[label] = FontMetrics.new font
      end
      [fonts, font_metrics]
    end

    def self.include_in pdf

      pdf.spatials :characters do |parser|
        state = []
        page = nil
        fonts = {}
        font_metrics = {}
        page_n = 0
        render_state = {
          :tm => Matrix.identity(3),
          :tlm => Matrix.identity(3)
        }

        # parser.for :resource_font do |data|
        #   puts data
        #   fonts[data[0]] = data[1]
        #   font_metrics[data[0]] = FontMetrics.new data[1]
        #   nil
        # end

        parser.for :begin_page do |data|
          page = data[0]
          page_n = page_n.next

          fonts, font_metrics = build_fonts page

          state << {
            :h_scale => 100,
            :char_spacing => 0,
            :word_spacing => 0,
            :leading => 0,
            :rise => 0,
            :font => nil,
            :font_metrics => nil,
            :font_size => 0,
            :ctm => Matrix.identity(3)
          }
          nil
        end

        parser.for :end_page do |data|
          state.pop
          nil
        end

        parser.for :begin_text_object do |data|
          render_state = {
            :tm => Matrix.identity(3),
            :tlm => Matrix.identity(3)
          }
          nil
        end

        # Graphics state operators.

        parser.for :set_graphics_state_parameters do |data|
          # TODO Handle gs graphics state dictionary set operation for
          # :Font dictionary entries. Probably why font is sometimes nil.
          # puts data
          nil
        end

        parser.for :save_graphics_state do |data|
          state.push state.last.dup
          nil
        end

        parser.for :restore_graphics_state do |data|
          state.pop
          nil
        end

        parser.for :concatenate_matrix do |data|
          a, b, c, d, e, f = data
          ctm = state.last[:ctm]
          state.last[:ctm] = Matrix[ [a, b, 0], [c, d, 0], [e, f, 1] ] * ctm
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
          render_state[:tm] = Matrix[
            [1, 0, 0], [0, 1, 0], [data[0], data[1], 1]
          ] * render_state[:tlm]
          render_state[:tlm] = render_state[:tm]
          nil
        end

        parser.for :move_text_position_and_set_leading do |data|
          state.last[:leading] = -data[1]
          render_state[:tm] = Matrix[
            [1, 0, 0], [0, 1, 0], [data[0], data[1], 1]
          ] * render_state[:tlm]
          render_state[:tlm] = render_state[:tm]
          nil
        end

        # Font change operators.

        parser.for :set_text_font_and_size do |data|
          state.last[:font] = fonts[data[0]]
          state.last[:font_metrics] = font_metrics[data[0]]
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
          render_state[:tm] = Matrix[ [a, b, 0], [c, d, 0], [e, f, 1] ]
          render_state[:tlm] = Matrix[ [a, b, 0], [c, d, 0], [e, f, 1] ]
          nil
        end

        # New line operators.

        parser.for :move_to_start_of_next_line do |data|
          render_state[:tm] = Matrix[
            [1, 0, 0], [0, 1, 0], [0, -state.last[:leading], 1]
          ] * render_state[:tlm]
          render_state[:tlm] = render_state[:tm]
          nil
        end

        # Show text operators.

        parser.for :set_spacing_next_line_show_text do |data|
          state.last[:word_spacing] = data[0]
          state.last[:char_spacing] = data[1]
          
          render_state[:tm] = Matrix[
            [1, 0, 0], [0, 1, 0], [0, -state.last[:leading], 1]
          ] * render_state[:tlm]
          render_state[:tlm] = render_state[:tm]

          make_text_runs data[2], 0, state, render_state, page, page_n
        end

        parser.for :move_to_next_line_and_show_text do |data|
          render_state[:tm] = Matrix[
            [1, 0, 0], [0, 1, 0], [0, -state.last[:leading], 1]
          ] * render_state[:tlm]
          render_state[:tlm] = render_state[:tm]
          
          make_text_runs data.first, 0, state, render_state, page, page_n
        end

        parser.for :show_text do |data|
          make_text_runs data.first, 0, state, render_state, page, page_n
        end
        
        parser.for :show_text_with_positioning do |data|
          data = data.first
          runs = []
          tj = 0
          
          data.each do |item|
            case item.class.to_s
            when "Fixnum", "Float"
              tj = item
            when "String"
              runs << make_text_runs(item, tj, state, render_state, page, page_n)
              tj = 0
            end
          end
          
          runs.flatten
        end
        
      end
    end

  end
end
