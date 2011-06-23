require 'pdf-reader'

# A DSL that aids in developing an understanding of the spatial
# construction of PDF pages.

module PdfExtract

  class Receiver

    def initialize pdf
      @pdf = pdf
      @listeners = {}
      @object_listeners = {}
      @posts = []
      @pres = []
    end

    def for callback_name, &block
      @listeners[callback_name] = {:type => @pdf.operating_type, :fn => block}
    end

    def objects type_name, options = {:paged => false}, &block
      @object_listeners[type_name] ||= []
      @object_listeners[type_name] << block
    end

    def pre &block
      @pres << {:type => @pdf.operating_type, :fn => block}
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
      @object_listeners.each_pair do |type, listeners|
        listeners.each do |listener|
            spatial_objects[type].each { |obj| listener.call obj }
        end
      end
    end

    def call_posts
      @posts.each do |post|
        spatial_objects = post[:fn].call
        self.add_spatial_objects post[:type], spatial_objects
      end
    end

    def call_pres
      @pres.each do |pre|
        pre[:fn].call
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

    def invoke_calls type_name, filename, spatial_options
      if spatial_options[:paged]

        if self.object_calls?
          # Invoke each object call with paged objects.
          @object_listeners.each_pair do |type, listeners|
            paged = @pdf.paged_objects type
            paged.each_pair do |page, objs|
              # Before all listeners for each page, call
              # pre fns.
              self.call_pres
              
              listeners.each do |listener|
                objs.each { |obj| listener.call obj }
              end

              # After all listeners have been called for the
              # page, call posts.
              self.call_posts
            end
          end
        end
        
      else

        self.call_pres
        if self.object_calls?
          self.call_object_listeners @pdf.spatial_objects
        end
        self.call_posts

      end
      
      if self.for_calls?
        self.expand_listeners_to_callback_methods
        PDF::Reader.file filename, self
        @pdf.spatial_objects[type_name].compact!
      end
    end

  end

  class Pdf
    
    attr_accessor :operating_type, :spatial_calls, :spatial_builders, :spatial_objects
    attr_accessor :spatial_options
    
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
    end

    def explicit_call? name
      @spatial_calls.count { |obj| obj[:name] == name and obj[:explicit] } > 0
    end

    def paged_objects type
      paged_objs = {}
      
      if @spatial_objects[type]
        @spatial_objects[type].each do |obj|
          paged_objs[obj[:page]] ||= []
          paged_objs[obj[:page]] << obj
        end
      end

      paged_objs
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

