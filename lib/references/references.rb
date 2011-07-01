module PdfExtract
  module References

    @@min_letter_ratio = 0.2
    @@max_letter_ratio = 0.5

    def self.split_refs s
      # Find sequential numbers and use them as partition points.

      s = s[s.index(/\d/)..-1]
      last_n = -1
      current_ref = ""
      refs = []
      parts = s.partition(/\d+/)

      while not parts[1].length.zero?
        if last_n == -1
          last_n = parts[1].to_i
        elsif last_n == -1 || parts[1].to_i == last_n.next
          current_ref += parts[0]
          refs << {
            :content => current_ref,
            :order => last_n
          }
          current_ref = ""
          last_n = last_n.next
        else
          current_ref += parts[0] + parts[1]
        end

        parts = parts[2].partition(/\d+/)
      end

      refs
    end
    
    def self.include_in pdf
      pdf.spatials :references, :depends_on => [:sections] do |parser|

        refs = []

        parser.objects :sections do |section|
          if section[:letter_ratio] >= @@min_letter_ratio &&
              section[:letter_ratio] <= @@max_letter_ratio
            refs += split_refs section[:content]
          end
        end

        parser.after do
          refs
        end

      end
    end

  end
end
