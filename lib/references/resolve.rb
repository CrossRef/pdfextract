require 'cgi'
require 'nokogiri'
require 'open-uri'
require 'net/http'

module PdfExtract::Resolve

  class Sigg

    def self.find ref
      url = "http://api.labs.crossref.org/search?q=#{CGI.escape(ref)}"
      resolved = {}
      begin
        doc = Nokogiri::HTML(open url)
      
        result = doc.at_css "div.result"
        unless result.nil?
          score = result.at_css("span.cr_score").content.to_s
          if score.to_i >= 90
            doi = result.at_css "span.doi" 
            resolved[:doi] = doi.content.sub "http://dx.doi.org/", ""
          end
        end
      rescue
      end
      resolved
    end
    
  end
  
  class FreeCite
    
    def self.find ref
      Net::HTTP.start "freecite.library.brown.edu" do |http|
        r = http.post "/citations/create", "citation=#{ref}",
                      "Accept" => "text/xml"
        doc = Nokogiri::XML r.body
        
        {
          :title => doc.at_xpath("//title").content,
          :journal => doc.at_xpath("//journal").content,
          :pages => doc.at_xpath("//pages").content,
          :year => doc.at_xpath("//year").content
        }
      end
    end
    
  end
  
  class CrossRef
    
    def self.find ref
    end
    
  end
  
  @@resolvers = [Sigg]
  
  def self.resolvers= resolver
    @@resolvers = resolver
  end

  def self.add_resolver resolver
    unless @@resolvers.contains? resolver
      @@resolvers << resolver
    end
  end

  def self.find ref
    ref = ref.dup
    @@resolvers.each do |resolver|
      ref.merge! resolver.find(ref[:content])
    end
    ref
  end
  
end
