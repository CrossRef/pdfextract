require_relative 'pdf'
require_relative 'model/characters'
require_relative 'model/chunks'
require_relative 'model/regions'
require_relative 'analysis/titles'
require_relative 'analysis/margins'
require_relative 'analysis/zones'
require_relative 'analysis/columns'
require_relative 'analysis/sections'
require_relative 'references/references'
require_relative 'references/reverse_resolve'
require_relative 'view/png_view'
require_relative 'view/pdf_view'
require_relative 'view/xml_view'

module PdfExtract

  @@views = {
    :xml => XmlView,
    :png => PngView,
    :pdf => PdfView
  }

  @@parsers = [Characters, Chunks, Regions, Titles,
               Margins, Zones, Columns, Sections, References, ResolvedReferences]
  
  def self.parse filename, &block
    pdf = Pdf.new

    @@parsers.each do |p|
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
    @@views[short_name]
  end

  def self.view filename, options = {}, &block
    pdf = parse filename, &block
    view_class(options[:as]).new(pdf, filename).render
  end

end
