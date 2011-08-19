require_relative '../language'
require_relative '../spatial'

module PdfExtract
  module Sections

    @@width_ratio = 0.8

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

          # Every region with a width to body width ratio higher
          # than @@width_ratio is considered to be the body of a
          # section. Multiple occurant bodies are concatenated.

          # A single region between two section body regions is considered
          # to be the section header of the section below.

          # Any other regions, including multiple regions between two
          # section body regions, are discarded.

          sections = []
          non_sections = []
          
          pages.each_pair do |page, columns|
            columns.each do |c|
              column = c[:column]
              c[:regions].each do |region|
                
                # TODO Use line_height instead.
                if region[:width] >= (column[:width] * @@width_ratio)
                  
                  case non_sections.count
                  when 0
                    
                    last = sections.last
                    if !last.nil? && last[:font] == region[:font] &&
                        last[:line_height].floor == region[:line_height].floor
                      content = Spatial.merge_lines(sections.last, region, {})
                      sections.last.merge!(content)
                    else
                      sections << Spatial.drop_spatial(region)
                    end
                    
                  when 1
                    section = Spatial.drop_spatial region
                    section[:name] = Spatial.get_text_content(non_sections.last)
                    sections << section
                    non_sections = []
                  else
                    sections << Spatial.drop_spatial(region)
                    non_sections = []
                  end
                  
                else
                  non_sections << region
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
