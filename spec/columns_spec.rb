require "rspec"
require_relative "../lib/analysis/columns"
require_relative "../lib/multi_range"

describe PdfExtract::Columns do

  before :each do
    @triple = PdfExtract::MultiRange.new
    @triple.append (10..20)
    @triple.append (30..40)
    @triple.append (50..60)

    @double = PdfExtract::MultiRange.new
    @double.append (10..30)
    @double.append (40..60)

    @single = PdfExtract::MultiRange.new
    @single.append (10..60)
  end

  it "should report column masks as agreeing with boundaries" do
    double_boundaries = [35]
    triple_boundaries = [25, 45]

    masks = [@single, @double, @triple]
    
    PdfExtract::Columns.check_for_columns(double_boundaries, masks).count.should == 1
    PdfExtract::Columns.check_for_columns(triple_boundaries, masks).count.should == 1
  end

  it "should find the shortest width for a column gap" do
    multi_ranges = (1..5).map do |alteration|
      multi = PdfExtract::MultiRange.new
      multi.append (0..10 - alteration)
      multi.append (11..20)
      multi
    end

    PdfExtract::Columns.smallest_incident_gap(multi_ranges, 10).should == (9..11)
  end

end

RSpec::Core::Runner.run([])
