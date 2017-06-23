# Gem spec for pdf-extract.
Gem::Specification.new do |s|
  s.name = "pdf-extract"
  s.version = "0.1.1"
  s.summary = "PDF content extraction tool and library."
  s.files = Dir.glob("{bin,lib,data}/**/*")
  s.executables << "pdf-extract"
  s.authors = ["Karl Jonathan Ward"]
  s.email = ["kward@crossref.org"]
  s.homepage = "http://github.com/CrossRef/pdfextract"
  s.required_ruby_version = ">=1.9.1"

  s.add_dependency 'pdf-reader', '= 1.2.0'
  s.add_dependency 'nokogiri', '>= 1.5.0'
  s.add_dependency 'prawn', '>= 0.11.1'
  s.add_dependency 'sqlite3', '>= 1.3.4'
  s.add_dependency 'commander', '>= 4.0.4'
  s.add_dependency 'json', '>= 1.5.1'
  s.add_dependency 'rb-libsvm', '>= 1.1.3'

  s.add_development_dependency 'mongo', '>= 1.9.2'
  s.add_development_dependency 'bson_ext', '>= 1.9.2'
  s.add_development_dependency 'rake', '>= 10.1.0'
end

