require 'cgi'
require 'nokogiri'
require 'open-uri'
require 'net/http'
require 'json'

module PdfExtract::Resolve

  class Sigg

    def self.find ref
      resolved = {:doi => nil, :score => nil}
      url = "http://search.crossref.org/dois?q=#{CGI.escape(ref)}&rows=1"
      query = JSON.parse(open(url).read())
      unless query.nil? or query[0].nil?
        resolved[:doi] = query[0]["doi"].sub "http://dx.doi.org/",""
        resolved[:score] = query[0]["score"]
        puts "Found DOI from Text: #{resolved[:doi]} (Score: #{resolved[:score]})"
      else
        puts "Could not resolve DOI for following reference: #{ref}. Skipping..."
      end
      resolved
    end

  end

  # class Sigg

  #   def self.find ref
  #     url = "http://api.labs.crossref.org/search?q=#{CGI.escape(ref)}"
  #     resolved = {}
  #     begin
  #       doc = Nokogiri::HTML(open url)

  #       result = doc.at_css "div.result"
  #       unless result.nil?
  #         score = result.at_css("span.cr_score").content.to_s
  #         if score.to_i >= 90
  #           doi = result.at_css "span.doi"
  #           resolved[:doi] = doi.content.sub "http://dx.doi.org/", ""
  #         end
  #       end
  #     rescue
  #     end
  #     resolved
  #   end

  # end

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

  class SimpleTextQuery

    @@cookie = nil

    def self.find ref
      create_session

      post = Net::HTTP::Post.new "/SimpleTextQuery"
      post.add_field "Cookie", @@cookie
      post.add_field "Referer", "http://www.crossref.org/SimpleTextQuery"
      post.set_form_data({
        "command" => "Submit",
        "freetext" => ref,
        #"emailField" => "kward@crossref.org",
        "doiField" => "",
        #"username" => "",
        #"password" => ""
      })
      response = Net::HTTP.start "www.crossref.org" do |http|
        http.request post
      end

      doc = Nokogiri::HTML response.body
      doi = doc.at_css "td.resultB > a"

      if doi.nil?
        {}
      else
        {:doi => doi.content.sub("doi:", "")}
      end
    end

    def self.create_session
      if @@cookie.nil?
        Net::HTTP.start "www.crossref.org" do |http|
          response = http.get "/SimpleTextQuery"
          @@cookie = response["Set-Cookie"]
        end
      end
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
