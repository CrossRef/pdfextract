# -*- coding: utf-8 -*-
require_relative '../language'
require_relative '../spatial'
require_relative '../kmeans'

module PdfExtract
  module Sections

    Settings.declare :width_ratio, {
      :default => 0.9,
      :module => self.name,
      :description => "Minimum ratio of text region width to containing column width for a text region to be considered as part of an article section."
    }

    def self.match? a, b
      # A must have a width around the width of B and have the same
      # font size.
      avg_width = (a[:width] + b[:width]) / 2.0
      matched_width = (a[:width] - b[:width]).abs <= avg_width * 0.1
      matched_font_size = a[:line_height].round(2) == b[:line_height].round(2)
      matched_width && matched_font_size
    end

    def self.candidate? pdf, region, column
      # Regions that make up sections or headers must be
      # both less wide than their column width and,
      # unless they are a single line, must be within the
      # width_ratio.
      width_ratio = pdf.settings[:width_ratio]
      within_column = region[:width] <= column[:width]
      within_column && (region[:width].to_f / column[:width]) >= width_ratio
    end

    def self.possible_header? pdf, region, column
      # Possible headers are narrower than the column width_ratio
      # but still within the column bounds. They must also be at least
      # as wide as they are tall (otherwise we may have a table
      # column, which should be ignored for purposes of determing
      # page flow).
      within_column = region[:width] <= column[:width]
      within_column && (region[:width] >= region[:height])
    end

    def self.reference_cluster clusters
      # Find the cluster with name_ratio closest to 0.1
      # Those are our reference sections.
      ideal = 0.1
      ref_cluster = nil
      smallest_diff = 1

      clusters.each do |cluster|
        diff = (cluster[:centre][:name_ratio] - ideal).abs
        if diff < smallest_diff
          ref_cluster = cluster
          smallest_diff = diff
        end
      end

      ref_cluster
    end

    def self.clusters_to_spatials clusters
      clusters.map do |cluster|
        cluster[:items].each do |item|
          centre = cluster[:centre].values.map { |v| v.round(3) }.join ", "
          item[:centre] = centre
        end
        cluster[:items]
      end.flatten
    end

    def self.add_content_stats sections, page_count
      sections.map do |section|
        last_page = section[:components].max {|c| c[:page]}[:page]
        content = Spatial.get_text_content section
        Spatial.drop_spatial(section).merge({
          :letter_ratio => Language.letter_ratio(content),
          :year_ratio => Language.year_ratio(content),
          :cap_ratio => Language.cap_ratio(content),
          :name_ratio => Language.name_ratio(content),
          :word_count => Language.word_count(content),
          :lateness => (last_page / page_count.to_f)
        })
      end
    end

    def self.include_in pdf
      pdf.spatials :sections, :depends_on => [:regions, :columns] do |parser|

        columns = []

        parser.objects :columns do |column|
           columns << {:column => column, :regions => []}
        end

        parser.objects :regions do |region|
          containers = columns.reject do |c|
            column = c[:column]
            not (column[:page] == region[:page] && Spatial.contains?(column, region, 1))
          end

          containers.first[:regions] << region unless containers.empty?
        end

        parser.after do
          # Sort regions in each column from highest to lowest.
          columns.each do |c|
            c[:regions].sort_by! { |r| -r[:y] }
          end

          # Group columns into pages.
          pages = {}
          columns.each do |c|
            pages[c[:column][:page]] ||= []
            pages[c[:column][:page]] << c
          end

          # Sort bodies on each page from x left to right.
          pages.each_pair do |page, columns|
            columns.sort_by! { |c| c[:column][:x] }
          end

          sections = []
          merging_region = nil

          pages.each_pair do |page, columns|
            columns.each do |container|
              column = container[:column]

              container[:regions].each do |region|
                if candidate? pdf, region, column
                  if !merging_region.nil? && match?(merging_region, region)
                    content = Spatial.merge_lines(merging_region, region, {})

                    merging_region.merge!(content)

                    merging_region[:components] << Spatial.get_dimensions(region)
                  elsif !merging_region.nil?
                    sections << merging_region
                    merging_region = region.merge({
                      :components => [Spatial.get_dimensions(region)]
                    })
                  else
                    merging_region = region.merge({
                      :components => [Spatial.get_dimensions(region)]
                    })
                  end
                elsif possible_header? pdf, region, column
                  # Split sections, ignore the header
                  sections << merging_region if !merging_region.nil?
                  merging_region = nil
                end
              end
            end
          end

          sections <<  merging_region if not merging_region.nil?

          # We now have sections. Add information to them.
          # add_content_types sections
          sections = add_content_stats sections, pages.keys.count

          # Score sections into categories based on their textual attributes.
          ref_ideals = {
            :name_ratio => [0.14, 1],
            :letter_ratio => [0.23, 6],
            :year_ratio => [0.05, 10],
            :cap_ratio => [0.49, 10],
            :lateness => [0.96, 6]
          }

          Spatial.score(sections, ref_ideals, :reference_score)

          sections
        end

      end
    end

  end
end
