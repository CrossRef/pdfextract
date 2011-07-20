
# Grab some DOIS and metadata via OAI PMH.

# Record metadata in the test-data dir.

# If there is no corresponding PDF in the test-data dir, download it using
# get-pdf.

require 'cgi'
require 'net/http'
require 'uri/http'

def query_uri prefix, issue, year
  URI::HTTP.build({
    :host => "oai.crossref.org",
    :path => "/OAIHandler",
    :query => {
      :verb => "ListIdentifiers",
      :metadataPrefix => "cr_unixml"
    }
  })
end

def 


  
Net::HTTP.start "oai.crossref.org" do |http|

  URI::HTTP.build {
    :path => "/OAIHandler",
    :query => {
      :verb => "ListIdentifiers",
      :metadataPrefix => "cr_unixml"
    }
  }
