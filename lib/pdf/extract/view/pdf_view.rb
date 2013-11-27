require 'prawn'
require_relative 'abstract_view'

module PdfExtract
  class PdfView < AbstractView

    def render options={}
      Prawn::Document.new :template => @filename do |doc|
        objects.each_pair do |type, objs|
          last_page = 1
          color = auto_color
          doc.go_to_page last_page
          doc.fill_color color
          
          objs.each do |obj|
            unless obj[:page].nil?
              if obj[:page] != last_page
                last_page = obj[:page]
                doc.go_to_page last_page
                doc.fill_color color
              end
              
              # XXX Works, but why?
              pos = [obj[:x] - 36, obj[:y] + obj[:height] - 36]
              width = obj[:width]
              height = obj[:height]
              
              doc.transparent 0.2 do
                doc.fill_rectangle pos, width, height
              end
            end
          end
        end
      end
    end

    def self.write render, filename
      render.render_file filename
    end
    
  end
end

