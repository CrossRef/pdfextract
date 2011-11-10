require 'pdf-reader'

module PdfExtract

  class Settings
    
    @@defaults = {}
    
    def self.declare key, opts={}
      default_hash = {
        :default => "",
        :description => "",
        :module => ""
      }.merge(opts)
      @@defaults[key] = default_hash
    end
    
    def initialize
      @settings = {}
      @agents = {}
    end
  
    def [] key
      @settings[key] ||
        (@@defaults[key] && @@defaults[key][:default]) ||
        raise("Attempt to use undeclared setting \"#{key}\"")
    end
    
    def set key, value, agent=""
      if @@defaults[key]
        @settings[key] = value.to_f
        @agents[key] = agent
      else
        raise "Attempt to set an undefined setting \"#{key}\""
      end
    end

    def unmodified
      @@defaults.reject { |k, v| @settings[k] }
    end

    def modified
      @settings
    end

    def agent key
      @agents[key]
    end
    
  end
  
  class Receiver

    def initialize pdf
      @pdf = pdf
      @listeners = {}
      @object_listeners = {}
    end

    def for callback_name, &block
      @listeners[callback_name] = {:type => @pdf.operating_type, :fn => block}
    end

    def objects type_name, &block
      @object_listeners[type_name] ||= []
      @object_listeners[type_name] << block
    end

    def before &block
      @before = block
    end

    def after &block
      @after = {:type => @pdf.operating_type, :fn => block}
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

    def call_after
      self.add_spatial_objects @after[:type], @after[:fn].call unless @after.nil?
    end

    def call_before
      @before.call unless @before.nil?
    end

    def for_calls?
      @listeners.size > 0
    end

    def object_calls?
      @object_listeners.size > 0
    end

    def add_spatial_objects default_type, objs
      if objs.class != Array
        objs = [objs] unless objs.nil?
        objs = [] if objs.nil?
      end

      objs.each do |obj|
        type = obj.delete(:group) || default_type
        @pdf.spatial_objects[type] ||= []
        @pdf.spatial_objects[type] << obj
      end
    end

    def invoke_calls filename, spatial_options
      if spatial_options[:paged]
          
        paged_objs = {}
        @object_listeners.each_pair do |type, _|
          @pdf.paged_objects(type).each_pair do |page, objs|
              paged_objs[page] ||= {}
            paged_objs[page][type] = objs
          end
        end
        
        paged_objs.each_pair do |page, objs|
          call_before

          if object_calls?
            @object_listeners.each_pair do |type, listeners|
              listeners.each do |listener|
                if objs[type].nil?
                  raise "#{@pdf.operating_type} is missing a dependency on #{type}"
                end
                objs[type].each { |obj| listener.call obj }
              end
            end
          end
          
          call_after
        end
        
      else

        call_before
        if object_calls?
          call_object_listeners @pdf.spatial_objects
        end
        call_after

      end
      
      if for_calls?
        expand_listeners_to_callback_methods
        #PDF::Reader.file filename, self, :raw_text => true

        reader = PDF::Reader.new filename, :raw_text => true
        reader.pages.each do |page|
          begin_page page
          page.walk self
          end_page page
        end
      end
    end

  end

  class Pdf
    
    attr_accessor :operating_type, :spatial_calls, :spatial_builders, :spatial_objects
    attr_accessor :spatial_options, :settings
    
    def method_missing name, *args
      raise "No such spatial type #{name}"
    end

    def spatials name, options = {}, &block
      add_spatials_method name, options, &block
    end

    def initialize
      @spatial_builders = {}
      @spatial_calls = []
      @spatial_objects = {}
      @spatial_options = {}
      @settings = Settings.new
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

    def [](type)
      @spatial_objects[type]
    end

    def set setting, value, agent=""
      @settings.set setting, value, agent
    end

    private

    def append_deps deps_list
      # TODO if explicit is true, overwrite non-explicit deps.
      deps_list.each do |dep|
        append_deps @spatial_options[dep].fetch(:depends_on, [])
        if @spatial_calls.count { |obj| obj[:name] == dep }.zero?
          @spatial_calls << {
            :name => dep,
            :explicit => false
          }
        end
      end
    end
    
    def add_spatials_method name, options={}, &block
      options = {:depends_on => [], :defined_by => []}.merge options
      
      @spatial_objects[name] = []
      @spatial_builders[name] = proc { |receiver|
        @operating_type = name
        block.call receiver unless block.nil?
      }
      @spatial_options[name] = options

      p = Proc.new do
        append_deps options[:depends_on]

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

