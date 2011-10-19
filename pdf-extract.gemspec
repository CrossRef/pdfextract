# Gem spec for pdf-extract.
Gem::Specification.new do |s|
  s.name = "pdf-extract"
  s.version = "0.0.1"
  s.summary = "PDF text, region, section and section header extraction tool and library."
  s.files = Dir.glob("{bin,lib,data}/**/**/*")
  s.executables << "pdf-extract"
  s.authors = ["Karl Jonathan Ward"]
  s.email = ["kward@crossref.org"]
  s.homepage = "http://github.com/CrossRef/pdfextract"
  s.required_ruby_version = ">=1.9.1"

  s.add_dependency 'pdf-reader', '>= 1.0.0'
  s.add_dependency 'nokogiri', '>= 1.4.4'
  s.add_dependency 'rmagick', '>= 2.13.1'
  s.add_dependency 'prawn', '>= 0.11.1'
end

