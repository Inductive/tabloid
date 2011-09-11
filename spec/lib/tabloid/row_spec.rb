require "spec_helper"
require 'nokogiri'
require 'fastercsv'

describe Tabloid::Row do
  before do
    @row = Tabloid::Row.new(
        :columns => [
            Tabloid::ReportColumn.new(:col1, "Column 1", :hidden => true),
            Tabloid::ReportColumn.new(:col2, "Column 2")
        ],
        :data    => [1, 2]
    )
  end
  context "producing output" do
    describe "#to_csv" do
      it "includes visible columns" do
        rows = FasterCSV.parse(@row.to_csv)
        rows.first.should include("2")
      end
      it "does not include hidden columns" do
        rows = FasterCSV.parse(@row.to_csv)
        rows.first.should_not include("1")
      end
    end

    describe "#to_html" do
      before do
        @doc = Nokogiri::HTML(@row.to_html)
      end
      it "should have a single row" do
        (@doc / "tr").count.should == 1
      end
      it "should have classes on the columns" do
        (@doc / "td[class='col2']").count.should == 1
      end
      it "should not include hidden columns" do
        (@doc / "td[class='col1']").count.should == 0

      end
    end


  end
  describe "accessing contents with []" do
    it "allows numeric access" do
      @row[0].should == 1
    end
    it "allows access by element key" do
      @row[:col1].should == 1
    end
  end
end