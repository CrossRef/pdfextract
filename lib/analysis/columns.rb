# -*- coding: utf-8 -*-
require_relative "../multi_range"
require_relative "../equal_rows"

module PdfExtract
  module Columns

    Settings.declare :column_sample_count, {
      :default => 8,
      :module => self.name,
      :description => "Columns are detected by sampling :column_sample_count equal rows across a page and examing the number of regions incident with each row."
    }

    Settings.declare :max_column_count, {
      :default => 3,
      :module => self.name,
      :description => "The maximum number of columns that can ever occur. During column detection column counts larger than :max_column_count will be disregarded."
    }

    Settings.declare :column_merge_threshold, {
      :default => 20,
      :module => self.name,
      :description => "Column detection can uncover areas that look like columns but are in fact something more like bullet points or other column-like structures that should really be merged into an adjacent column. Columns under :column_merge_threshold width will be merged into their nearest adjacent column."
    }
    
    def self.columns_at y, body_regions
      x_mask = MultiRange.new

      body_regions.each do |region|
        if region[:y] <= y && (region[:y] + region[:height]) >= y
          x_mask.append(region[:x] .. (region[:x] + region[:width]))
        end
      end

      x_mask
    end

    def self.include_in pdf
      deps = [:characters, :bodies]
      pdf.spatials :columns, :paged => true, :depends_on => deps do |parser|
        
        rows = nil
        body = nil
        
        parser.objects :bodies do |b|
          body = b
          rows = EqualRows.new b, pdf.settings[:column_sample_count]
        end

        parser.objects :characters do |character|
          rows.append character
        end

        parser.after do
          # TODO Find largest gap(s)
          
          column_ranges = rows.column_masks

          # Merge ranges within each column range if they are very small.
          column_ranges.each do |column_range|
            column_range.merge_under! pdf.settings[:column_merge_threshold]
          end
          
          # Discard those with a coverage of 0.
          column_ranges.reject! { |r| r.covered.zero? }
          
          # Discard those with more than x columns. They've probably hit a table.
          column_ranges.reject! { |r| r.count > pdf.settings[:max_column_count] }

          if column_ranges.count.zero?
            []
          else
            # Take the columns that are widest.
            widest = column_ranges.map { |r| r.avg }.max
            column_ranges.reject! { |r| r.avg < widest }
            
            # Find the highest column count.
            most = column_ranges.max_by { |r| r.count }.count
            column_ranges.reject! { |r| r.count != most }

            column_ranges.first.ranges.map do |range|
              body.merge({:x => range.min, :width => range.max - range.min })
            end
          end
        end
        
      end
    end

  end
end
