require 'nokogiri'

require_relative 'abstract_view'
require_relative '../language'

module PdfExtract
  class XmlView < AbstractView

    @@ignored_attributes = [:content, :page, :page_width, :page_height]

    def render
      pages = {}
      page_params = {}
      pageless = {}
      
      objects.each_pair do |type, objs|
        objs.each do |obj|
          if obj.key? :page
            pages[obj[:page]] ||= {}
            pages[obj[:page]][type] ||= []
            
            pages[obj[:page]][type] << obj
            
            page_params[obj[:page]] ||= {
              :width => obj[:page_width],
              :height => obj[:page_height],
              :number => obj[:page]
            }
          else
            pageless[type] ||= []
            pageless[type] << obj
          end
        end
      end

      builder = Nokogiri::XML::Builder.new do |xml|
        xml.pdf {
          pageless.each_pair do |type, objs|
            objs.each do |obj| write_obj_to_xml obj, type, xml end
          end
          
          pages.each_pair do |page_number, obj_types|
            xml.page(page_params[page_number]) {
              obj_types.each_pair do |type, objs|
                objs.each do |obj| write_obj_to_xml obj, type, xml end
              end
            }
          end
        }
      end

      builder.to_xml
    end

    def write_obj_to_xml obj, type, xml
      attribs = obj.reject { |k, _| @@ignored_attributes.include? k }
      nested_objs = attribs.reject { |_, v| ! (v.kind_of?(Hash) || v.kind_of?(Array)) }
      attribs = attribs.reject { |_, v| v.kind_of?(Hash) || v.kind_of?(Array) }
      
      xml.send singular_name(type.to_s), attribs do
        if obj.key? :content
          xml.text Language::transliterate(obj[:content].to_s)
        end

        nested_objs.each do |name, nested_obj|
          element_name = singular_name name.to_s
          if nested_obj.kind_of? Hash
            write_obj_to_xml nested_obj, element_name, xml
          elsif nested_obj.kind_of? Array
            nested_obj.each do |item|
              write_obj_to_xml item, element_name, xml
            end
          end
        end
      end
    end

    def self.write render, filename
      File.open filename, "w" do |file|
        file.write render
      end
    end
    
  end
end
