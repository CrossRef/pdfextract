require_relative "../spatial"

module PdfExtract
  module References

    # TODO Line delimited citations.
    # TODO Indent /outdent delimited citations.
    
    @@min_letter_ratio = 0.2
    @@max_letter_ratio = 0.5
    @@min_word_count = 3

    def self.partition_by ary, &block
      remaining = ary.dup
      parts = []      
      while not remaining.empty?
        parts << remaining.take_while { |elem| yield elem }
        remaining.drop arys[-1].length
        parts << remaining.first unless remaining.empty?
      end
      parts
    end

    # def self.split_by_margin lines
    #   delimiting_x_offset = lines.first[:x_offset].floor
    #   parts = partition_by lines { |line| lines[:x_offset].foor != delimiting_x_offset }
    #   parts.map { |part| {:content => part.join " "} }
    # end

    # def self.split_by_line_spacing lines
    #   delimiting_spacing = lines[1][:spacing].floor
    #   parts = partition_by lines { |line| lines[:spacing].floor != delimiting_spacing }
    #   parts.map { |part| {:content => part.join " "} }
    # end

    def self.split_by_delimiter s
      # Find sequential numbers and use them as partition points.

      # Determine the charcaters that are most likely part of numeric
      # delimiters.
      
      before = {}
      after = {}
      last_n = -1
      
      s.scan /[^\d]?\d+[^\d]/ do |m|
        n = m[/\d+/].to_i
        
        if last_n == -1
          before[m[0]] ||= 0
          before[m[0]] = before[m[0]].next
          after[m[-1]] ||= 0
          after[m[-1]] = after[m[-1]].next
          last_n = n
        elsif n == last_n.next
          before[m[0]] ||= 0
          before[m[0]] = before[m[0]].next
          after[m[-1]] ||= 0
          after[m[-1]] = after[m[-1]].next
          last_n = last_n.next
        end
      end

      b_s = "" if before.length.zero?
      b_s = "\\" + before.max_by { |_, v| v }[0] unless before.length.zero?
      a_s = "" if after.length.zero?
      a_s = "\\" + after.max_by { |_, v| v }[0] unless after.length.zero?

      if ["", "\\[", "\\ "].include?(b_s) && ["", "\\.", "\\]", "\\ "].include?(a_s)

        # Split by the delimiters and record separate refs.
      
        last_n = -1
        current_ref = ""
        refs = []
        parts = s.partition(Regexp.new "#{b_s}\\d+#{a_s}")
        
        while not parts[1].length.zero?
          n = parts[1][/\d+/].to_i
          if last_n == -1
            last_n = n
        elsif n == last_n.next
            current_ref += parts[0]
            refs << {
              :content => current_ref.strip,
              :order => last_n
            }
            current_ref = ""
            last_n = last_n.next
          else
            current_ref += parts[0] + parts[1]
          end

          parts = parts[2].partition(Regexp.new "#{b_s}\\d+#{a_s}")
        end
        
        refs << {
          :content => (current_ref + parts[0]).strip,
          :order => last_n
        }
        
        refs

      else
        []
      end
    end
    
    def self.include_in pdf
      pdf.spatials :references, :depends_on => [:sections] do |parser|

        refs = []

        parser.objects :sections do |section|
          if section[:letter_ratio] >= @@min_letter_ratio &&
              section[:letter_ratio] <= @@max_letter_ratio &&
              section[:word_count] >= @@min_word_count
            #refs += split_by_margin section[:lines]
            refs += split_by_delimiter Spatial.get_text_content section
          end
        end

        parser.after do
          refs
        end

      end
    end

  end
end
