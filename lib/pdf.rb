require 'pdf-reader'

# A DSL that aids in developing an understanding of the spatial
# construction of PDF pages.

module PdfExtract

  class SpatialObject < Hash
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
        if @spatial_calls.count { |obj| obj[:name] == dep } == 0
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
  
end

