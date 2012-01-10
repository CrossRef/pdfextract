require "rspec"
require_relative "../lib/multi_range"

describe PdfExtract::MultiRange do

  before(:each) do
    @multi_range = PdfExtract::MultiRange.new
  end

  it "should merge overlapping ranges" do
    @multi_range.append (10..20)
    @multi_range.append (18..30)
    @multi_range.count.should == 1
  end

  it "should maintain distinct ranges" do
    @multi_range.append (10..20)
    @multi_range.append (-5..0)
    @multi_range.append (30..40)
    @multi_range.count.should == 3
  end

  it "should ignore fully occluded ranges" do
    @multi_range.append (0..100)
    @multi_range.append (0..10)
    @multi_range.append (90..100)
    @multi_range.append (0..100)
    @multi_range.append (50..60)
    @multi_range.count.should == 1
  end

  it "should remove out of bounds ranges upon intersection" do
    @multi_range.append (10..20)
    @multi_range.append (40..50)
    inter = @multi_range.intersection (25..35)
    inter.count.should == 0
  end

  it "should keep ranges fully within an intersection" do
    @multi_range.append (10..20)
    @multi_range.append (30..40)
    inter = @multi_range.intersection (5..45)
    inter.count.should == 2
  end

  it "should truncate ranges that fall on intersection bounds" do
    @multi_range.append (0..10)
    @multi_range.append (50..60)
    @multi_range.append (100..110)
    inter = @multi_range.intersection (5..105)
    inter.min.should == 5
    inter.max.should == 105
    inter.ranges.first.min.should == 5
    inter.ranges.last.max.should == 105
  end
    
  it "should locate the widest gap correctly" do
    @multi_range.append (0..10)
    @multi_range.append (15..20)
    @multi_range.append (25..30)
    @multi_range.append (40..50)
    @multi_range.widest_gap.should == (30..40)
  end

  it "should locate the widest range correctly" do
    @multi_range.append (0..10)
    @multi_range.append (11..18)
    @multi_range.append (20..80)
    @multi_range.append (100..110)
    @multi_range.widest.should == (20..80)
  end

  it "should report min and max correctly" do
    @multi_range.append (10..100)
    @multi_range.append (-100..-10)
    @multi_range.max.should == 100
    @multi_range.min.should == -100
  end

  it "should calculate the average range width correctly" do
    @multi_range.append (10..20)
    @multi_range.append (30..40)
    @multi_range.append (50..60)
    @multi_range.avg.should == 10
  end

  it "should calculate range width total correctly" do
    @multi_range.append (10..20)
    @multi_range.append (30..40)
    @multi_range.append (50..60)
    @multi_range.covered.should == 30
  end

  it "should calculate min and max uncovered points correctly" do
    @multi_range.append (10..20)
    @multi_range.append (30..40)
    @multi_range.append (50..60)
    @multi_range.max_excluded.should == 50
    @multi_range.min_excluded.should == 20
  end

end
    
RSpec::Core::Runner.run([])
