
module PdfExtract
  module Titles

    def self.include_in pdf
      pdf.spatials :titles, :depends_on => [:regions] do |parser|
        titles = []
        title_slop_factor = 0.2
        
        parser.objects :regions do |region|
          titles << region
        end

        parser.after do
          # A title should:
          #   be longer than one letter,
          titles.reject! { |r| r[:content].strip.length < 2 }

          #   be in the top half of a page,
          titles.reject! { |r| r[:y] < (r[:page_height] / 2.0) }

          #   be no less tall than a factor of the tallest text,
          titles.sort_by! { |r| -r[:line_height] }
          tallest_line = titles.first[:line_height]
          title_slop = tallest_line - (tallest_line * title_slop_factor)
          titles.reject! { |r| r[:line_height] < title_slop }
          
          #   be on the earliest page with text,
          titles.sort_by! { |r| r[:page] }
          first_page = titles.first[:page]
          titles.reject! { |r| r[:page] != first_page }

          #   be the highest of the above.
          titles.sort_by! { |r| -r[:y] }

          if titles.count.zero?
            []
          else
            title = titles.take(1).dup
            title.delete :page
            title
          end
        end
      end
    end

  end
end

