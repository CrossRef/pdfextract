
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
      @ranges.sort_by { |r| -r.max }.first.max
    end

    def min
      @ranges.sort_by { |r| r.min }.first.min
    end

    def widest
      widest = @ranges.sort_by { |r| r.max - r.min }.last
      widest.max - widest.min
    end

    def narrowest
      narrowest = @ranges.sort_by { |r| r.max - r.min }.first
      narrowest.max - narrowest.min
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

  end
end
