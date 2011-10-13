require_relative "../spatial"

module PdfExtract
  module References

    # TODO Line delimited citations.
    # TODO Indent /outdent delimited citations.
    
    @@min_score = 200
    @@min_word_count = 3

    def self.partition_by ary, &block
      remaining = ary.dup
      parts = []      
      while not remaining.empty?
        matching = remaining.take_while { |elem| yield elem }
        unless matching.empty?
          parts << matching
          remaining = remaining.drop matching.length
        end
        unless remaining.empty?
          parts << [remaining.first]
          remaining = remaining.drop 1
        end
      end
      parts
    end

    def self.split_by_margin lines
      delimiting_x_offset = lines.first[:x_offset].floor
      parts = partition_by(lines) { |line| line[:x_offset].floor != delimiting_x_offset }
      parts.map { |part| {:content => part.map { |line| line[:content] }.join(" ")} }
    end

    def self.split_by_line_spacing lines
      delimiting_spacing = lines[1][:spacing].floor
      parts = partition_by(lines) { |line| line[:spacing].floor != delimiting_spacing }
      parts.map { |part| {:content => part.map { |line| line[:content] }.join(" ")} }
    end

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

    def self.multi_margin? lines
      lines.uniq { |line| line[:x_offset].floor }.count > 1
    end

    def self.multi_spacing? lines
      lines.uniq { |line| line[:spacing].floor }.count > 1
    end
    
    def self.include_in pdf
      pdf.spatials :references, :depends_on => [:sections] do |parser|

        refs = []

        parser.objects :sections do |section|
          # TODO Take top x%, fix Infinity coming back from score.
          if section[:reference_score] >= 120 &&
              section[:reference_score] <= 20000 &&
              section[:word_count] >= @@min_word_count

            if multi_margin? section[:lines]
              refs += split_by_margin section[:lines]
            elsif multi_spacing? section[:lines]
              refs += split_by_spacing section[:lines]
            else
              refs += split_by_delimiter Spatial.get_text_content section
            end
            
          end
        end

        parser.after do
          refs
        end

      end
    end

  end
end
