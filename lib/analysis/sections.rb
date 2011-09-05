require_relative '../language'
require_relative '../spatial'

module PdfExtract
  module Sections

    @@letter_ratio_threshold = 0.1
    
    def self.match? a, b
      lh = a[:line_height].floor == b[:line_height].floor
      f = a[:font] == b[:font]

      lra = Language.letter_ratio(Spatial.get_text_content a)
      lrb = Language.letter_ratio(Spatial.get_text_content b)

      lr = (lra - lrb).abs <= @@letter_ratio_threshold

      lh && f && lr
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
            not (column[:page] == region[:page] && Spatial.contains?(column, region))
          end

          containers.first[:regions] << region unless containers.count.zero?
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
          non_sections = []
          
          pages.each_pair do |page, columns|
            columns.each do |c|
              column = c[:column]
              c[:regions].each do |region|

                if region[:width] >= column[:width]
                  non_sections << region
                elsif !sections.last.nil? && match?(last, region)
                  content = Spatial.merge_lines(sections.last, region, {})
                  sections.last.merge!(content)
                else
                  sections << region
                end
                
              end
            end
          end

          

          sections.map do |section|
            content = Spatial.get_text_content section
            section.merge({
              :letter_ratio => Language.letter_ratio(content),
              :word_count => Language.word_count(content)           
            })
          end
        end
        
      end
    end

  end
end
