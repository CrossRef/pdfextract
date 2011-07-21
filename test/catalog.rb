#!/usr/bin/env ruby

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
program :description, "Build a PDF catalog, with metadata."

def query_uri verb, options={}
  prefix = options[:prefix]
  journal = options[:journal]
  year = options[:year]

  if prefix.nil? || (!year.nil? && journal.nil?)
    fail "Must specify one of prefix, prefix:journal, or prefix:journal:year."
  end
  
  set = CGI.escape [prefix, journal, year].compact.join(":")
  q = "verb=#{verb}&metadataPrefix=cr_unixml&set=#{set}"
  URI::HTTP.build({
    :host => "oai.crossref.org",
    :path => "/OAIHandler",
    :query => q
  })
end

def parse_dois xml
  doc = Nokogiri::XML::Document.parse xml
  identifiers = doc.css "identifier"
  identifiers.map { |id| id.text.sub "info:doi/", "" }
end

def get_dois options
  uri = query_uri "ListIdentifiers", options

  Net::HTTP.start uri.host do |http|
    response = http.get uri.request_uri

    if response.code.to_i == 200
      parse_dois response.body
    else
      fail "Failed to get metadata. OAI server returned: #{response.code}"
    end
  end
end

def catalog_filename
  File.join File.dirname(__FILE__), "catalog.json"
end

def read_catalog filename=catalog_filename
  if File.exists? filename
    File.open filename do |file|
      JSON.load file
    end
  else
    say "Created new catalog."
    {}
  end
end

def write_catalog catalog, filename=catalog_filename
  File.open filename, "w" do |file|
    file.write catalog.to_json
  end
end

def with_catalog &block
  catalog = read_catalog
  yield catalog
  write_catalog catalog
end

$set_spec = {}

["prefix", "journal", "year"].each do |item|
  global_option "--#{item.downcase}=#{item.upcase}" do |value|
    $set_spec[item.to_sym] = value
  end
end

command :populate do |c|
  c.syntax = "catalog populate --prefix=10.5555 --journal=5 --year=2002"
  c.description = "Add Crossref Metadata to a catalog."

  c.action do |args, options|
    dois = get_dois $set_spec

    with_catalog do |catalog|
      dois.each do |doi|
        catalog[doi] = {
          :doi => doi,
          :owner => $set_spec[:prefix]
        }
      end
      say "Added or updated #{dois.count} records."
    end
  end
end

command :pdfs do |c|
  c.syntax = "catalog download"
  c.description = "Locate and download PDFs for DOIs in a catalog."

  c.action do |args, options|
  end
end
