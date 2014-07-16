require_relative 'extract/pdf.rb'
require_relative 'extract/model/characters.rb'
require_relative 'extract/model/chunks.rb'
require_relative 'extract/model/regions.rb'
require_relative 'extract/analysis/titles.rb'
require_relative 'extract/analysis/margins.rb'
require_relative 'extract/analysis/zones.rb'
require_relative 'extract/analysis/columns.rb'
require_relative 'extract/analysis/sections.rb'
require_relative 'extract/references/references.rb'
require_relative 'extract/references/resolved_references.rb'
require_relative 'extract/view/pdf_view.rb'
require_relative 'extract/view/xml_view.rb'
require_relative 'extract/view/bib_view.rb'

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
    add_view :xml, XmlView
    add_view :bib, BibView
  end

  init

end
