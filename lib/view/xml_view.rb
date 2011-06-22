require 'nokogiri'

require_relative 'abstract_view'
require_relative '../language'

module PdfExtract
  class XmlView < AbstractView

    def render
      pages = {}
      page_params = {}
      ignored_attributes = [:content, :page, :page_width, :page_height]
      
      objects.each_pair do |type, objs|
        objs.each do |obj|
          pages[obj[:page]] ||= {}
          pages[obj[:page]][type] ||= []

          pages[obj[:page]][type] << obj

          page_params[obj[:page]] ||= {
            :width => obj[:page_width],
            :height => obj[:page_height],
            :number => obj[:page]
          }
        end
      end

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.pdf {
          pages.each_pair do |page_number, obj_types|
            xml.page(page_params[page_number]) {
              obj_types.each_pair do |type, objs|
                objs.each do |obj|

                  attribs = obj.reject { |k, _| ignored_attributes.include? k }
                  xml.send singular_name(type.to_s), attribs do
                    if obj.key? :content
                      xml.text Language::transliterate(obj[:content].to_s)
                    end
                  end
                
                end
              end
            }
          end
        }
      end

      builder.to_xml
    end

    def self.write render, filename
      File.open filename, "w" do |file|
        file.write render
      end
    end
    
  end
end
