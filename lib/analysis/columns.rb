# -*- coding: utf-8 -*-
require_relative "../multi_range"
require_relative "../equal_rows"

module PdfExtract
  module Columns

    def self.include_in pdf
      deps = [:characters, :bodies]
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

        parser.after do
          # Find the mask with widest gap for:
          # - whole body
          # - top half of body
          # - bottom half of body
          # - middle half of body
          with_max_gap = page_masks.max do |mask|
            gap = mask.widest_gap
            if gap.nil?
              0
            else
              gap.max - gap.min
            end
          end
          
          # Choose mask that has the widest gap as columns
          with_max_gap.ranges.map do |range|
            body.merge({:x => range.min, :width => range.max - range.min})
          end
        end
        
      end
    end

  end
end
