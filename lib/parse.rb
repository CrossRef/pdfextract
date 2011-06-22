require_relative 'pdf'
require_relative 'model/characters'
require_relative 'model/chunks'
require_relative 'model/regions'
require_relative 'analysis/bodies'
require_relative 'analysis/titles'
require_relative 'view/png_view'
require_relative 'view/pdf_view'
require_relative 'view/xml_view'

module PdfExtract

  @@view_dictionary = {
    :xml => PdfExtract::XmlView,
    :png => PdfExtract::PngView,
    :pdf => PdfExtract::PdfView
  }
  
  def self.parse filename, &block
    pdf = Pdf.new

    Characters.include_in pdf
    Chunks.include_in pdf
    Regions.include_in pdf
    Bodies.include_in pdf
    Titles.include_in pdf
    
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
  
  def self.view_class short_name
    @@view_dictionary[short_name]
  end

  def self.view filename, options = {}, &block
    pdf = parse filename, &block
    view_class(options[:as]).new(pdf, filename).render
  end

end
