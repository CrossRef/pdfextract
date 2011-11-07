# -*- coding: utf-8 -*-
require_relative "../spatial"

module PdfExtract
  module References
 
    Settings.default :min_score, 8.0
    Settings.default :min_sequence_count, 3
    Settings.default :max_reference_order, 1000

    def self.partition_by ary, &block
      matching = []
      parts = []
      ary.each do |item|
        if yield(item)
          parts << matching
          matching = []
        end
        matching << item
      end
      parts << matching
      parts.reject { |p| p.empty? }
    end

    def self.frequencies lines, delimit_key
      fs = {}
      lines.each do |line|
        val = line[delimit_key].floor
        fs[val] ||= 0
        fs[val] = fs[val].next
      end

      ary = []
      fs.each_pair do |key, val|
        ary << {:value => key, :count => val}
      end

      ary.sort_by { |item| item[:count] }.reverse
    end

    def self.select_delimiter lines, delimit_key
      frequencies(lines, delimit_key)[1][:value]
    end

    def self.split_by_margin lines
      delimiting_x_offset = select_delimiter lines, :x_offset
      lines = lines.drop_while { |l| l[:x_offset].floor != delimiting_x_offset }
      parts = partition_by(lines) { |line| line[:x_offset].floor == delimiting_x_offset }
      parts.map { |part| {:content => part.map { |line| line[:content] }.join(" ")} }
    end

    def self.split_by_line_spacing lines
      delimiting_spacing = select_delimiter lines, :spacing
      lines = lines.drop_while { |l| l[:spacing].floor != delimiting_spacing }
      parts = partition_by(lines) { |line| line[:spacing].floor == delimiting_spacing }
      parts.map { |part| {:content => part.map { |line| line[:content] }.join(" ")} }
    end

    def self.split_by_delimiter pdf, s
      # Find sequential numbers and use them as partition points.

      # Determine the charcaters that are most likely part of numeric
      # delimiters.
      
      after = {}
      before = {}
      last_n = -1
      
      s.scan /[^\d]?\d+[^\d]/ do |m|
        n = m[/\d+/].to_i
        if n < pdf.settings[:max_reference_order]
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
      end

      b_s = "" if before.length.zero?
      b_s = "\\" + before.max_by { |_, v| v }[0] unless before.length.zero?
      a_s = "" if after.length.zero?
      a_s = "\\" + after.max_by { |_, v| v }[0] unless after.length.zero?

      # TODO Turn into settings. Needs typed settings
      if ["", "\\[", "\\ "].include?(b_s) && ["", "\\.", "\\]", "\\ "].include?(a_s)

        # Split by the delimiters and record separate refs.
        
        last_n = -1
        current_ref = ""
        refs = []
        parts = s.partition(Regexp.new "#{b_s}?\\d+#{a_s}")
        
        while not parts[1].length.zero?
          n = parts[1][/\d+/].to_i          
          if n < pdf.settings[:max_reference_order] && last_n == -1
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

          parts = parts[2].partition(Regexp.new "#{b_s}?\\d+#{a_s}")
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

    def self.numeric_sequence? pdf, content
      last_n = -1
      seq_count = 0
      content.scan /\d+/ do |m|
         # Avoid misinterpreting years as sequence
        if m.to_i < pdf.settings[:max_reference_order]
          if last_n == -1
            last_n = m.to_i
          elsif last_n.next == m.to_i
            last_n = last_n.next
            seq_count = seq_count.next
          end
        end
      end

      seq_count >= pdf.settings[:min_sequence_count]
    end
    
    def self.include_in pdf
      pdf.spatials :references, :depends_on => [:sections] do |parser|

        refs = []

        parser.objects :sections do |section|
          # TODO Take top x%, fix Infinity coming back from score.
          if section[:reference_score] >= pdf.settings[:min_score]
            if numeric_sequence? pdf, Spatial.get_text_content(section)
              refs += split_by_delimiter pdf, Spatial.get_text_content(section)
            elsif multi_margin? section[:lines]
              refs += split_by_margin section[:lines]
            elsif multi_spacing? section[:lines]
              refs += split_by_line_spacing section[:lines]
            end
          end
        end

        parser.after do
          # TODO Ideally we wouldn't see the ref headers here.
          refs.reject {|ref| ref[:content].downcase.strip =~ /references?/ }
        end

      end
    end

  end
end
