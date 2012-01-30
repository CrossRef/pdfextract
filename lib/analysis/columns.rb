# -*- coding: utf-8 -*-
require_relative "../multi_range"
require_relative "../equal_rows"

module PdfExtract
  module Columns

    # Returns the number of page_masks that are not incident with
    # any value in boundaries.
    def self.check_for_columns boundaries, page_masks
      # Ignore masked regions that contain no content
      page_masks = page_masks.reject { |mask| mask.covered == 0 }
      
      page_masks = page_masks.reject do |mask|
        covered_boundaries = boundaries.reject { |b| mask.cover? b }
        covered_boundaries.count.zero?
      end

      page_masks
    end

    def self.smallest_incident_gap masks, gap_point
      gaps = masks.map { |mask| mask.gap_at gap_point }
      gaps.sort_by { |gap| gap.max - gap.min }.first
    end
      
    def self.include_in pdf
      deps = [:characters, :images, :bodies]
      pdf.spatials :columns, :paged => true, :depends_on => deps do |parser|
        
        body = nil
        page_parts = []
        page_masks = []
        
        parser.objects :bodies do |b|
          body = b
          
          # Whole body, bottom half, top half, middle half. 
          page_parts =
            [
             b,
             b.merge({:height => b[:height] / 2}),
             b.merge({:height => b[:height] / 2, :y => b[:y] + b[:height] / 2}),
             b.merge({:height => b[:height] / 2, :y => b[:y] + b[:height] / 4})
            ]

          page_masks = []
          page_parts.count.times { page_masks << MultiRange.new }
        end

        parser.objects :characters do |character|
          page_parts.each_index do |idx|
            if Spatial.contains?(page_parts[idx], character)
              page_masks[idx].append character[:x]..(character[:x]+character[:width])
            end
          end
        end

        parser.objects :images do |image|
          page_parts.each_index do |idx|
            if Spatial.contains?(page_parts[idx], image)
              page_masks[idx].append image[:x]..(image[:x]+image[:width])
            end
          end
        end

        parser.after do
          # Check for 1, 2 or 3 columns
          page_left = body[:x]
          page_right = body[:x] + body[:width]
          page_width = body[:width]
          
          two_column_boundaries = [page_left + (page_width / 2)]
          three_column_boundaries = [page_left + (page_width / 3),
                                     page_left + ((page_width / 3) * 2)]

          two_agree_masks = check_for_columns two_column_boundaries, page_masks
          three_agree_masks = check_for_columns three_column_boundaries, page_masks

          if two_agree_masks.count.zero? && three_agree_masks.count.zero?
            # one column
            [body]
          elsif two_agree_masks.count >= three_agree_masks.count
            # two columns
            gaps = two_agree_masks.map do |mask|
              mask.gap_at(page_left + (page_width / 2))
            end.compact
            column_gap = gaps.max { |gap| gap.max - gap.min }
            [body.merge({:width => column_gap.min - page_left}),
             body.merge({:width => page_right - column_gap.max,
                         :x => column_gap.max})]
          else
            # three columns
            left_gaps = three_agree_masks.map do |mask|
              mask.gap_at(page_left + (page_width / 3))
            end.compact
            right_gaps = three_agree_masks.map do |mask|
              mask.gap_at(page_left + ((page_width / 3) * 2))
            end.compact
            left_gap = left_gaps.max { |gap| gap.max - gap.min }
            right_gap = right_gaps.max { |gap| gap.max - gap.min }
            [body.merge({:width => left_gap.min - page_left}),
             body.merge({:x => left_gap.max, :width => right_gap.max - left_gap.min}),
             body.merge({:x => right_gap.max, :width => page_right - right_gap.max})]
          end
        end
        
      end
    end

  end
end
