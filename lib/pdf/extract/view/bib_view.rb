require 'net/http'

require_relative 'abstract_view'
require_relative '../language'

module PdfExtract
  class BibView < AbstractView

    def render options={}

      bibs = []
      
      objects.each_pair do |type, objs|
        objs.each do |obj|

          if obj.key? :doi and obj.key? :score
            unless obj[:doi].nil? or obj[:score].nil? or obj[:score] < 1
              url = "http://api.crossref.org/v1/works/#{obj[:doi]}/transform/application/x-bibtex"
              begin
                bib = open(URI.encode(url)).read()
              rescue URI::InvalidURIError
                puts "DOI not a valid URL: #{obj[:doi]}"
              rescue OpenURI::HTTPError
                puts "DOI not found on CrossRef: #{obj[:doi]}"
              else
                puts "Found BibTeX from DOI: #{obj[:doi]}"
                bibs << bib
              end
            end
            
          else
            raise "Must run extract-bib with --resolved_references flag"
          end
        end
      end

      bibs.join("\n")
    end

    def self.write render, filename
      File.open filename, "w" do |file|
        file.write render
      end
    end
    
  end
end
