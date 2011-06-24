
module PdfExtract
  class MultiRange

    def initialize
      @ranges = []
    end

    def append range
      merged = false
      @ranges.map! do |r|
        if r.include?(range.min) || r.include?(range.max)
          merged = true
          [r.min, range.min].min .. [r.max, range.max].max
        else
          r
        end
      end
      @ranges << range unless merged

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
    end

    def min_excluded
      if @min_excluded.nil?
        @min_excluded = @ranges.first.min if count == 1
        @min_excluded = @ranges.sort_by { |r| r.max }.first.max unless count == 1
      end
    end

    def max
      @max ||= @ranges.sort_by { |r| -r.max }.first.max
    end

    def min
      @min ||= @ranges.sort_by { |r| r.min }.first.min
    end

    def count
      @ranges.count
    end

  end
end
