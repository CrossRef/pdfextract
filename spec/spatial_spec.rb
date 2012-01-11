require "rspec"
require "../lib/spatial"

describe PdfExtract::Spatial do

  before(:each) do
    @with_lines = {
      :x => 0,
      :y => 0,
      :width => 100,
      :height => 100,
      :lines =>
      [
       {
         :y_offset => 0,
         :x_offset => 0,
         :content => "First line."
       },
       {
         :y_offset => 10,
         :x_offset => 10,
         :content => "Second line."
       }
      ]
    }

    @with_content = {
      :x => 0,
      :y => 0,
      :width => 100,
      :height => 100,
      :content => "First line.\nSecond line."
    }

    @central = {
      :x => -1,
      :y => -1,
      :width => 2,
      :height => 2
    }

    @contained = {
      :x => -0.5,
      :y => -0.5,
      :width => 1,
      :height => 1
    }

    # These hit all N, S, E, W, NE, SE, NW, SW
    
    @adjacent =
      [[0, 2],[0, -2],[2, 0],[-2, 0],[-2, -2],[2, 2],[-2, 2],[2, -2]].map do |a|
      {
        :x => -1 + a[0],
        :y => -1 + a[1],
        :width => 2,
        :height => 2
      }
    end

    @distinct =
      [[0, 3],[0, -3],[3, 0],[-3, 0],[-3, -3],[3, 3],[-3, 3],[3, -3]].map do |a|
      {
        :x => -1 + a[0],
        :y => -1 + a[1],
        :width => 2,
        :height => 2
      }
    end

    @overlapping =
      [[0, 1],[0, -1],[1, 0],[-1, 0],[-1, -1],[1, 1],[-1, 1],[1, -1]].map do |a|
      {
        :x => -1 + a[0],
        :y => -1 + a[1],
        :width => 2,
        :height => 2
      }
    end
  end

  it "should return correct line counts for both content types" do
    PdfExtract::Spatial.line_count(@with_lines).should == 2
    PdfExtract::Spatial.line_count(@with_content).should == 2
  end

  it "should return the same content for :lines and :content style objects" do
    lines_text = PdfExtract::Spatial.get_text_content @with_lines
    content_text = PdfExtract::Spatial.get_text_content @with_content
    lines_text.should == content_text
  end

  context "contains?" do
    it "should return false for distinct regions" do
      @distinct.each do |r|
        PdfExtract::Spatial.contains?(@central, r).should == false
      end
    end

    it "should return false for adjacent regions" do
      @adjacent.each do |r|
        PdfExtract::Spatial.contains?(@central, r).should == false
      end
    end

    it "should return false for overlapping regions" do
      @overlapping.each do |r|
        PdfExtract::Spatial.contains?(@central, r).should == false
      end
    end

    it "should return true for a contained region" do
      PdfExtract::Spatial.contains?(@central, @contained).should == true
    end

    it "should return true for the same region" do
      PdfExtract::Spatial.contains?(@central, @central).should == true
    end
  end

  context "overlap?" do
    it "should not overlap in either direction for distinct regions" do
      # Should overlap in neither direction.
      @distinct.each do |r|
        [[:x, :width], [:y, :height]].map do |a|
          PdfExtract::Spatial.overlap?(a[0], a[1], @central, r)
        end.reject {|i| i == false}.should have(0).items
      end
    end

    it "should overlap in one direction for adjacent regions" do
      @adjacent.each do |r|
        [[:x, :width], [:y, :height]].map do |a|
          PdfExtract::Spatial.overlap?(a[0], a[1], @central, r)
        end.reject {|i| i == false}.should have(1).items
      end
    end

    it "should overlap in one or two directions for overlapping regions" do
      @overlapping.each do |r|
        result = [[:x, :width], [:y, :height]].map do |a|
          PdfExtract::Spatial.overlap?(a[0], a[1], @central, r)
        end.reject { |i| i == false }
        result.should have_at_least(1).items
        result.should have_at_most(2).items
      end
    end

    it "should overlap in two directions for a contained region" do
      [[:x, :width], [:y, :height]].map do |a|
        PdfExtract::Spatial.overlap?(a[0], a[1], @central, @contained)
      end.reject {|i| i == false}.should have(2).items
    end
  end
  
end

RSpec::Core::Runner.run([])
