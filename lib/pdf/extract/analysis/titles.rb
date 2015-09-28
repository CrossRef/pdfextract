require_relative "../spatial"

module PdfExtract
  module Titles

    Settings.declare :title_slop, {
      :default => 0.2,
      :module => self.name,
      :description => "Regions of text whose font size is less than :title_slop percent of the largest font size in a PDF will be disregarded as candidate titles. Value must be 0 - 1."
    }

    def self.include_in pdf
      pdf.spatials :titles, :depends_on => [:regions] do |parser|
        titles = []
        
        parser.objects :regions do |region|
          titles << region
        end

        parser.after do
          # A title should:
          #   be longer than one letter,
          titles.reject! { |r| Spatial.get_text_content(r).strip.length < 2}

          #   be in the top half of a page,
          titles.reject! { |r| r[:y] < (r[:page_height] / 2.0) }

          #   be no less tall than a factor of the tallest text,
          titles.sort_by! { |r| -r[:line_height] }
          if not titles.count.zero?
            tallest_line = titles.first[:line_height]
            title_slop = tallest_line - (tallest_line * pdf.settings[:title_slop])
            titles.reject! { |r| r[:line_height] < title_slop }
          end
          
          #   be on the earliest page with text,
          titles.sort_by! { |r| r[:page] }
          if not titles.count.zero?
            first_page = titles.first[:page]
            titles.reject! { |r| r[:page] != first_page }
          end

          #   be the highest of the above.
          titles.sort_by! { |r| -r[:y] }

          if titles.count.zero?
            []
          else
            {
              :content => Spatial.get_text_content(titles.first),
              :line_height => titles.first[:line_height],
              :font => titles.first[:font]
            }
          end
        end
      end
    end

  end
end

