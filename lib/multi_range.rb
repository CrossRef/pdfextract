
module PdfExtract
  class MultiRange

    attr_accessor :ranges

    def initialize
      @ranges = []
    end

    def append range
      return if range.max.nil? || range.min.nil?

      incident = @ranges.select do |r|
        r.include?(range.min) || r.include?(range.max) ||
          range.include?(r.min) || range.include?(r.max)
      end
      
      incident << range

      non_incident = @ranges - incident

      non_incident << (incident.collect { |r| r.min }.min .. incident.collect { |r| r.max }.max)
      @ranges = non_incident

      @max_excluded = nil
      @min_excluded = nil
      @max = nil
      @min = nil

      @ranges.sort_by! { |r| r.min }
    end

    def max_excluded
      if @max_excluded.nil?
        @max_excluded = @ranges.first.max if count == 1
        @max_excluded = @ranges.sort_by { |r| -r.min }.first.min unless count == 1
      end
      @max_excluded
    end

    def min_excluded
      if @min_excluded.nil?
        @min_excluded = @ranges.first.min if count == 1
        @min_excluded = @ranges.sort_by { |r| r.max }.first.max unless count == 1
      end
      @min_excluded
    end

    def max
      @max ||= @ranges.sort_by { |r| -r.max }.first.max
    end

    def min
      @min ||= @ranges.sort_by { |r| r.min }.first.min
    end

    def avg
      @ranges.reduce(0) { |sum, r| sum += (r.max - r.min) } / @ranges.count.to_f
    end

    def covered
      @ranges.reduce(0) { |total, r| total += (r.max - r.min) }
    end

    def count
      @ranges.count
    end

    def merge_if!
      if count > 1
        i = 0
        while i < count - 1
          range = @ranges[i]
          range_length = range.max - range.min

          if yield(range)
            if i < count - 1 && i > 0
              space_to_right = @ranges[i+1].min - range.max
              space_to_left = range.min - @ranges[i-1].max
              
              if space_to_right >= space_to_left
                append(range.min..@ranges[i+1].max)
              else
                append(@ranges[i-1].min..range.max)
              end

            elsif i < count - 1
              append(range.min..@ranges[i+1].max)
            else
              append(@ranges[i-1].min..range.max)
            end
          end

          i = i.next
        end
      end
    end

    def merge_under! length
      merge_if! do |range|
        (range.max - range.min) <= length
      end
    end

    def merge_over! length
      merge_if! do |range|
        (range.max - range.min) >= length
      end
    end

    def intersection bounding_range
      # We want to keep ranges that are in one of these four
      # positions:
      # 1. min is less than bounding min but max is within bounds
      # 2. max is more than bounding max but min is within bounds
      # 3. min and max are within bounds.
      # 4. min is below bounding min and max is above bounding max.
      #    in this last case we can reset @ranges to a single
      #    range equal to the bounding range.

      kept_ranges = []
      
      @ranges.each do |range|
        if range.min <= bounding_range.min && range.max >= bounding_range.max
          kept_ranges = [(bounding_range.min..bounding_range.max)]
          break
        elsif bounding_range.include?(range.min) && bounding_range.include?(range.max)
          kept_ranges << range
        elsif range.max > bounding_range.max && bounding_range.include?(range.min)
          kept_ranges << (range.min..bounding_range.max)
        elsif range.min < bounding_range.min && bounding_range.include?(range.max)
          kept_ranges << (bounding_range.min..range.max)
        end
      end

      intersection = MultiRange.new
      intersection.ranges = kept_ranges
      intersection
    end

    def widest
      @ranges.reduce(0..0) do |widest, r|
        if (r.max-r.min) > (widest.max-widest.min)
          r
        else
          widest
        end
      end
    end

    def widest_gap
      if @ranges.count.zero?
        nil
      else
        gap_min = 0
        gap_max = 0
        last_range = nil
        @ranges.each do |range|
          if !last_range.nil? && (range.min - last_range.max > (gap_max - gap_min))
            gap_max = range.min
            gap_min = last_range.max
          end
          last_range = range
        end
        (gap_min..gap_max)
      end
    end

  end
end
