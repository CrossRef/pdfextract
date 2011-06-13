require 'pdf-reader'
require 'nokogiri'
require 'RMagick'

require_relative 'util'
require_relative 'characters'
require_relative 'text_chunks'
require_relative 'text_regions'

# A DSL that aids in developing an understanding of the spatial
# construction of PDF pages.

module PdfExtract

  class SpatialObject < Hash

    def operations
      @operations ||= {
        :grow_by => lambda { |original, modifier| original + modifier },
        :grow_by_percent => lambda { |original, pcnt| original * (1 + pcnt) },
        :shrink_by => lambda { |original, modifier| original - modifier },
        :shrink_by_percent => lambda { |original, pcnt| original * (1 - pcnt) },
        :set_to => lambda { |original, new| new },
        :set_to_percent => lambda { |original, pcnt| original * pcnt },
        :with => lambda { |original, p| p.call(original) }
      }
    end
    
    def alter op_schema
      op_schema.each_pair do |param, operations|
        operations.each_pair do |operation, value|
          self[param] = self.operations[operation].call(self[param], value)
        end
      end
    end
    
  end

  class Receiver

    def initialize pdf
      @pdf = pdf
      @listeners = {}
      @object_listeners = {}
      @posts = []
    end

    def for callback_name, &block
      @listeners[callback_name] = {:type => @pdf.operating_type, :fn => block}
    end

    def objects type_name, &block
      @object_listeners[type_name] ||= []
      @object_listeners[type_name] << block
    end

    def post &block
      @posts << {:type => @pdf.operating_type, :fn => block}
    end

    def expand_listeners_to_callback_methods
      # TODO merge on callback_name
      @listeners.each_pair do |callback_name, callback_handler|
        p = proc do |*args|
          spatial_objects = callback_handler[:fn].call args
          self.add_spatial_objects callback_handler[:type], spatial_objects
        end
        
        self.class.send :define_method, callback_name, p
      end
    end

    def call_object_listeners spatial_objects
      @object_listeners.each_pair do |type, fns|
        fns.each do |fn|
          spatial_objects[type].each do |obj|
            fn.call obj
          end
        end
      end
    end

    def call_posts
      @posts.each do |post|
        spatial_objects = post[:fn].call
        self.add_spatial_objects post[:type], spatial_objects
      end
    end

    def for_calls?
      @listeners.size > 0
    end

    def object_calls?
      @object_listeners.size > 0
    end

    def add_spatial_objects type, spatial_objects
      if not spatial_objects.nil?
        if spatial_objects.class != Array
          spatial_objects = [spatial_objects]
        end
        spatial_objects.each do |obj|
          @pdf.spatial_objects[type] << obj
        end
      end
    end

  end

  class Pdf
    
    attr_accessor :operating_type, :spatial_calls, :spatial_builders, :spatial_objects
    
    def method_missing name, *args
      throw StandardError.new "No such spatial type #{name}"
    end

    def spatials name, options = {}, &block
      add_spatials_method name, options, &block
    end

    def initialize
      @spatial_builders = {}
      @spatial_calls = []
      @spatial_objects = {}
      @spatial_options = {}

      self.spatials :images do
        parser.for :begin_inline_image_data do |data|
        end
      end
      
      self.spatials :v_margins, :depends_on => [:text_chunks] do
        # Mark off ranges of the x axis. AxisMask class?
      end
      
      self.spatials :h_margins, :depends_on => [:text_chunks] do
      end
      
      self.spatials :rows, :depends_on => [:h_margins] do
      end
      
      self.spatials :columns, :depends_on => [:v_margins, :rows] do
      end
      
      self.spatials :sections, :depends_on => [:text_regions, :columns] do
      end
    end

    def explicit_call? name
      @spatial_calls.count { |obj| obj[:name] == name and obj[:explicit] } > 0
    end

    private

    def append_deps deps_list
      deps_list.each do |dep|
        append_deps @spatial_options[dep].fetch(:depends_on, [])
        if @spatial_calls.collect { |obj| obj[:name] == dep }.empty?
          @spatial_calls << {
            :name => dep,
            :explicit => false
          }
        end
      end
    end
    
    def add_spatials_method name, options={}, &block
      @spatial_objects[name] = []
      @spatial_builders[name] = proc { |receiver|
        @operating_type = name
        block.call receiver
      }
      @spatial_options[name] = options

      p = Proc.new do
        append_deps options[:depends_on] if options[:depends_on]
        
        @spatial_calls << {
          :name => name,
          :explicit => true
        }
        
        @spatial_objects[name].each do |o|
          yield o
        end
      end

      self.class.send :define_method, name, p
    end
  end

  def self.parse filename, &block
    pdf = Pdf.new

    PdfExtract::Characters.include_in pdf
    PdfExtract::TextChunks.include_in pdf
    PdfExtract::TextRegions.include_in pdf
    
    yield pdf
    
    pdf.spatial_calls.each do |spatial_call|
      receiver = Receiver.new pdf
      pdf.spatial_builders[spatial_call[:name]].call receiver
      if receiver.object_calls?
        receiver.call_object_listeners pdf.spatial_objects
      end
      if receiver.for_calls?
        receiver.expand_listeners_to_callback_methods
        PDF::Reader.file filename, receiver
        pdf.spatial_objects[spatial_call[:name]].compact!
      end
      receiver.call_posts
    end
    
    pdf
  end

  def self.view filename, options = {}, &block
    pdf = parse filename, &block

    case options[:as]
    when :xml
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.pdf {
          pdf.spatial_objects.each_pair do |type, objs|
            if pdf.explicit_call? type
              objs.each do |obj|
                attribs = obj.reject {|key, value| key == :content }
                xml.send PdfExtract::Util::singular_name(type.to_s), attribs do
                  if obj.key? :content
                    xml.text obj[:content].to_s
                  end
                end
              end
            end
          end
        }
      end

      builder.to_xml
      
    when :html
      # TODO Write out html with nokogiri.
      raise "Not yet implemented"

    when :text
      # TODO Write out :content of spatial objects.
      raise "Not yet implemented"

    when :png
      img = Magick::Image.new(800, 1000) { self.background_color = "white" }
      
      pdf.spatial_objects.each_pair do |type, objs|
        objs.each do |obj|
          gc = Magick::Draw.new
          gc.fill "black"
          gc.rectangle(obj[:x], obj[:y], obj[:x] + obj[:width],
                       obj[:y] + obj[:height])
          gc.draw img
        end
      end
      
      img

    else
      # return a ruby data structure.
      pdf.spatial_objects
    end
  end
  
end

# Usage

#png = PdfExtract::view "/Users/karl/some.pdf", :as => :png do |pdf|
#  pdf.characters
#  pdf.text_chunks
#end

xml = PdfExtract::view "/Users/karl/some.pdf", :as => :xml do |pdf|
  pdf.text_chunks
end

# objs = PdfExtract::view "/Users/karl/some.pdf" do |pdf|
#   pdf.text_chunks
#   pdf.text_regions
# end

# objs[:text_regions].each do |region|
#   if region[:content] =~ /References/
#     puts "Maybe refs"
#   end
# end

# png = PdfExtract::view "/Users/karl/some.pdf", :as => :png do |pdf|
#   pdf.text_regions do |region|
#     if region[:content] =~ /References/
#       region[:color] = "blue"
#     else
#       region[:color] = "green"
#     end
#   end
# end

 puts xml

# png.write 'tmp.png'

