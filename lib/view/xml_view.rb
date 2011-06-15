require 'nokogiri'

require_relative 'abstract_view'

module PdfExtract
  class XmlView < AbstractView

    def render
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.pdf {
          objects.each_pair do |type, objs|
            objs.each do |obj|
              attribs = obj.reject {|key, value| key == :content }
              xml.send singular_name(type.to_s), attribs do
                if obj.key? :content
                  xml.text obj[:content].to_s
                end
              end
            end
          end
        }
      end
      builder.to_xml
    end

  end
end
