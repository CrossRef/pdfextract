
module PdfExtract
  module Titles

    def self.include_in pdf
      pdf.spatials :titles, :depends_on => [:regions] do |parser|
        # TODO Not only highest, but earliest page.
        title = {:line_height => 0, :y => 0}
        parser.objects :regions do |region|
          if region[:line_height] > title[:line_height] && region[:y] > title[:y]
            title = region
          end
        end

        parser.post do
          title.dup unless title[:content].nil?
          nil if title[:content].nil?
        end
      end
    end

  end
end
