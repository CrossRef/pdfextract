require 'nokogiri'

require_relative 'abstract_view'
require_relative '../language'

module PdfExtract
  class XmlView < AbstractView

    @@ignored_attributes = [:content]

    @@parent_ignored_attributes = [:page, :page_width, :page_height]

    @@numeric_attributes = [:x, :y, :width, :height, :line_height,
                            :page_height, :page_width, :x_offset, :y_offset,
                            :spacing, :letter_ratio, :cap_ratio, :year_ratio]

    # Return renderable attributes
    def get_xml_attributes obj, parent=true
      attribs = obj.reject { |k, _| @@ignored_attributes.include? k }
      if parent
        attribs = attribs.reject { |k, _| @@parent_ignored_attributes.include? k }
      end
      attribs = attribs.reject { |_, v| v.kind_of?(Hash) || v.kind_of?(Array) }
      attribs.each_pair do |k, v|
        if @@numeric_attributes.include?(k) || k.to_s =~ /.+_score/
          attribs[k] = v.round(@render_options[:round])
        end
      end
      attribs
    end

    def get_nested_objs obj
      nested = obj.reject { |_, v| ! (v.kind_of?(Hash) || v.kind_of?(Array)) }
      if @render_options[:lines]
        nested
      else
        nested.reject { |k, _| k == :lines }
      end
    end

    def render options={}
      @render_options = {:lines => true, :round => 2, :outline => false}.merge(options)

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

    def write_obj_to_xml obj, type, xml, parent=true
      xml.send singular_name(type.to_s), get_xml_attributes(obj, parent) do

        unless @render_options[:outline]
          if not @render_options[:lines]
            xml.text Language::transliterate(Spatial.get_text_content obj)
          elsif obj.key?(:content)
            xml.text Language::transliterate(obj[:content].to_s)
          end
        end

        get_nested_objs(obj).each do |name, nested_obj|
          element_name = singular_name name.to_s
          if nested_obj.kind_of? Hash
            write_obj_to_xml nested_obj, element_name, xml, false
          elsif nested_obj.kind_of? Array
            nested_obj.each do |item|
              write_obj_to_xml item, element_name, xml, false
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
