require 'cgi'
require 'nokogiri'
require 'open-uri'
require 'net/http'

# TODO These should be chainable functions, each taking a hash and adding its own
# attributes. The cmd line client will then allow --resolver sigg --resolver freecite
# if both are required.

module PdfExtract::Resolve

  class Sigg

    def self.find ref
      url = "http://api.labs.crossref.org/search?q=#{CGI.escape(ref)}"
      doc = Nokogiri::HTML(open url)
      
      result = doc.at_css "div.result"
      score = result.at_css("span.cr_score").content.to_s
      if score.to_i >= 90
        {:doi => result.at_css("span.doi").content.sub("http://dx.doi.org/", "")}
      else
        {}
      end
    end

  end
  
  class FreeCite
    
    def self.find ref
      Net::HTTP.start "freecite.library.brown.edu" do |http|
        r = http.post "/citations/create", "citation=#{ref}", "Accept" => "text/xml"
        doc = Nokogiri::XML r.body
        
        {
          :title => doc.at_xpath("title").content,
          :journal => doc.at_xpath("journal").content,
          :pages => doc.at_xpath("pages").content,
          :year => doc.at_xpath("year").content
        }
      end
    end
    
  end
  
  class CrossRef
    
    def self.resolve ref
    end
    
  end
  
  @@resolver = Sigg
  
  def self.resolver= resolver
    @@resolver = resolver
  end
  
  def self.find ref
    @@resolver.find ref
  end
  
end
