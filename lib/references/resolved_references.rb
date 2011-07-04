require_relative 'resolve'

module PdfExtract
  module ResolvedReferences

    def self.include_in pdf
      pdf.spatials :resolved_references, :depends_on => [:references] do |parser|

        resolved_refs = []
        
        parser.objects :references do |ref|
          resolved_refs << ref.merge(Resolve.find(ref))
        end

        parser.after do
          resolved_refs
        end

      end
    end

    def self.reverse_resolve ref
      
      url = "http://api.labs.crossref.org/search?q=#{CGI.escape(ref)}"
      doc = Nokogiri::HTML(open url)

      result = doc.at_css "div.result"
      score = result.at_css("span.cr_score").content.to_s
      if score.to_i >= 90
        result.at_css("span.doi").content.sub("http://dx.doi.org/", "")
      else
        ""
      end
    end

  end
end
