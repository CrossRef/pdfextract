require 'RMagick'

require_relative 'abstract_view'

module PdfExtract
  class PngView < AbstractView

    def render
      img = Magick::Image.new(800, 1000) { self.background_color = "white" }

      objects.each_pair do |type, objs|
        color = auto_color
        objs.each do |obj|
          gc = Magick::Draw.new
          gc.fill = "\##{color}"
          gc.rectangle(obj[:x], obj[:y], obj[:x] + obj[:width],
                       obj[:y] + obj[:height])
          gc.draw img
        end
      end
        
      img
    end
    
  end
end
