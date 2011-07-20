
# Grab some DOIS and metadata via OAI PMH.

# Record metadata in the test-data dir.

# If there is no corresponding PDF in the test-data dir, download it using
# get-pdf.

require 'cgi'
require 'net/http'
require 'uri/http'
require 'commander/import'
require 'nokogiri'
require 'json'

program :name, "catalog"
program :version, "0.0.1"

def query_uri verb, prefix, issue, year
  URI::HTTP.build({
    :host => "oai.crossref.org",
    :path => "/OAIHandler",
    :query => {
      :verb => verb,
      :metadataPrefix => "cr_unixml",
      :set => "#{prefix}:#{issue}:#{year}"                
    }
  })
end

def parse_dois xml
  doc = Nokogiri::XML::Document.new xml
  identifiers = doc.xpath "//identifier"
  identifiers.map { |id| id.text }
end

def get_dois prefix, issue, year
  uri = query_uri "ListIdentifiers", prefix, issue, year

  Net::HTTP.start uri.host do |http|
    response = http.get uri.request_uri

    if response == 200
      parse_dois response.body
    else
      fail "Failed to get metadata. OAI server returned: #{response.code}"
    end
  end
end

command :populate do |c|
  c.syntax = "catalog populate publisher_prefix:journal_id:year"
  c.description = "Add Crossref Metadata to a catalog."

  c.acton do |args, options|
    args.each do |limiting_set|
      dois = get_dois limiting_set.split(":")
      say dois.to_json
    end
  end
end

command :download do |c|
  c.syntax = "catalog download"
  c.description = "Locate and download PDFs for DOIs in a catalog."

  c.action do |args, options|
  end
end
