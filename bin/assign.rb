#!/usr/bin/env ruby

require "json"
require "highline"
require_relative "../lib/pdf-extract"

class Assign
  
  def initialize features, categories
    # The features of the data we wish to learn from.
    @features = features

    # The possible categorizations of data items.
    @categories = categories

    @hl = HighLine.new
  end

  def data_entry category, section
    entry = {}
    @features.each { |f| entry[f] = section[f] }
    entry[:file] = File.split(ARGV[0]).last
    entry[:category] = category
    entry[:word_count] = section[:word_count]

    puts entry
  end
  
  def with_category
    @hl.choose do |menu|
      menu.prompt = "Category?"
      @categories.each do |category|
        menu.choice(category) do
          yield category
        end
      end
    end
  end

end

# Display each section and ask if it is ref or non-ref.
features = [:letter_ratio, :name_ratio, :year_ratio, :cap_ratio]
categories = [:reference, :body, :mix, :none]
data = []
pdf = PdfExtract.parse(ARGV[0]) { |pdf| pdf.sections }
assign = Assign.new(features, categories)
  
pdf[:sections].each do |section|
  if section[:word_count] < 5
    # Low word count sections are definitely not ref sections.
    # Don't show them to the user.
    data << assign.data_entry(:none, section)
  else
    puts ""
    puts "-----"
    puts ""
    puts PdfExtract::Spatial.get_text_content(section)
    puts ""
    
    assign.with_category { |category| data << assign.data_entry(category, section) }
  end
end

puts data

# File.open(ARGV[1]).write(data.to_json)





