
module PdfExtract
  class MultiRange

    def initialize
      @ranges = []
    end

    def append range
      merged = false
      @ranges.map! do |r|
        if r.include? range.min
          merged = true
          r.min .. range.max
        elsif r.include? range.max
          merged = true
          range.min .. r.max
        else
          r
        end
      end
      @ranges << range unless merged
    end

    def max_excluded
      @ranges.sort_by { |r| -r.min }.first.min
    end

    def min_excluded
      @ranges.sort_by { |r| r.max}.first.max
    end

    def count
      @ranges.count
    end

  end
end
