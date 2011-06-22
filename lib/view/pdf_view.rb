require 'prawn'

require_relative 'abstract_view'

module PdfExtract
  class PdfView < AbstractView

    def render
      Prawn::Document.new :template => @filename do |doc|
        objects.each_pair do |type, objs|
          color = auto_color
          doc.fill_color color
          
          objs.each do |obj|
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
end
      
