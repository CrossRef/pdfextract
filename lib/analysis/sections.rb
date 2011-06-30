module PdfExtract
  module Sections

    @@width_ratio = 0.6

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

                # TODO Check font size?
                if region[:width] >= (column[:width] * @@width_ratio)
                  
                  case non_sections.count
                  when 0
                    sections.last.merge!({
                      :content => sections.last[:content] + ' ' + region[:content]
                    })
                  when 1
                    sections << {
                      :name => non_sections.last[:content],
                      :content => region[:content]
                    }
                    non_sections = []
                  else
                    sections << {
                      :content => region[:content]
                    }
                    non_sections = []
                  end
                  
                else
                  non_sections << region
                end
                
              end
            end
          end

          sections
          
        end
        
      end
    end

  end
end
