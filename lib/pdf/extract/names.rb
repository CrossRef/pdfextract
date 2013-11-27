require 'net/http'
require 'json'
require 'sqlite3'

require_relative '../extract.rb'

module PdfExtract::Names

  class NamesDatabase
    @@ambiguous_weighting = 0.0
    @@unambiguous_weighting = 1.0

    def self.path_to_data data_filename
      File.expand_path(File.join('../../../data', data_filename),
                       File.dirname(__FILE__))
    end

    @@db = SQLite3::Database.new(path_to_data("familynames.db"), {:readonly => true})
    @@stop_words = File.open(path_to_data("stopwords.txt")).read.split(",")

    def self.detect_names content
      words = content.split
      sum = 0.0

      words.each do |word|
        word = word.downcase

        if not @@stop_words.include? word && word.length > 1
          query_word = word.capitalize.gsub(/-(.)/) { |s|
            "-" + s[1].capitalize
          }

          @@db.execute("select * from names where name = ?", query_word) do |row|
            if row[2] == 1
              sum += @@ambiguous_weighting
            else
              sum += @@unambiguous_weighting
            end
          end
        end

      end

      if sum == 0
        {:name_frequency => 0}
      else
        {:name_frequency => (sum / words.length.to_f)}
      end
    end
  end

  class NamesService
    def self.detect_names content
      data = {:name_frequency => 0.0}
      begin
        response = Net::HTTP.start "names.crrd.dyndns.org" do |http|
          http.post "/detect", content
        end

        if response.code == "200"
          data = JSON.parse response.body
        end
      rescue
      end
      data
    end
  end

  class NoDetection
    def self.detect_names content
      {:name_frequency => 0.0}
    end
  end

  @@detector = NamesDatabase

  def self.detector= detector_class
    @@detector = detector_class
  end

  def self.detect_names content
    @@detector.detect_names content
  end

end

