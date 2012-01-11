require_relative 'pdf'
require_relative 'model/images'
require_relative 'model/characters'
require_relative 'model/chunks'
require_relative 'model/regions'
require_relative 'analysis/titles'
require_relative 'analysis/margins'
require_relative 'analysis/zones'
require_relative 'analysis/columns'
require_relative 'analysis/sections'
require_relative 'references/references'
require_relative 'references/resolved_references'
require_relative 'view/png_view'
require_relative 'view/pdf_view'
require_relative 'view/xml_view'

module PdfExtract

  @views = {}

  @parsers = []

  def self.add_view name, view_class
    @views[name] = view_class
  end

  def self.add_parser parser_class
    @parsers << parser_class
  end
  
  def self.parse filename, &block
    pdf = Pdf.new

    @parsers.each do |p|
      p.include_in pdf
    end
    
    yield pdf
    
    pdf.spatial_calls.each do |spatial_call|
      name = spatial_call[:name]
      receiver = Receiver.new pdf
      pdf.spatial_builders[name].call receiver
      receiver.invoke_calls filename, pdf.spatial_options[name]
    end
    
    pdf
  end
  
  def self.view_class short_name
    @views[short_name]
  end

  def self.view filename, options = {}, &block
    pdf = parse filename, &block
    view_class(options[:as]).new(pdf, filename).render options
  end

  def self.init
    add_parser Images
    add_parser Characters
    add_parser Chunks
    add_parser Regions
    add_parser Titles
    add_parser Margins
    add_parser Zones
    add_parser Columns
    add_parser Sections
    add_parser References
    add_parser ResolvedReferences

    add_view :pdf, PdfView
    add_view :png, PngView
    add_view :xml, XmlView
  end

  init

end
