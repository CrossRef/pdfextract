# -*- coding: utf-8 -*-
require 'matrix'

module PdfExtract
  module Images

    def self.get_xobj page, name
      @xobj_cache ||= {}
      @xobj_cache[name] ||= page.xobjects[name.to_sym].hash
      @xobj_cache[name]
    end

    def self.include_in pdf
      
      pdf.spatials :images do |parser|
        state = []
        page = nil
        page_n = 0

        parser.for :begin_page do |data|
          state << {
            :ctm => Matrix.identity(3)
          }
          page = data[0]
          page_n = page_n.next
          nil 
        end

        parser.for :end_page do |data|
          state.pop
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

        parser.for :invoke_xobject do |data|
          xobj = get_xobj page, data[0]

          if xobj[:Subtype] == :Image
            {
              :page => page_n,
              :x => state.last[:ctm].row(2)[0],
              :y => state.last[:ctm].row(2)[1],
              :width =>state.last[:ctm].row(0)[0],
              :height => state.last[:ctm].row(1)[1]
            }
          else
            nil
          end
        end

        # TODO Could think about implementing inline images but have
        # yet to encounter them.
        
        # parser.for :begin_inline_image do |data|
        #   puts "Begin inline image"
        #   puts data
        #   nil
        # end

        # parser.for :end_inline_image do |data|
        #   puts "End inline image"
        #   puts data
        #   nil
        # end
      end
      
    end

  end
end
