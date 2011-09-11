require "spec_helper"
require 'nokogiri'
require 'fastercsv'

describe Tabloid::Group do
  let(:columns) do
    [
        Tabloid::ReportColumn.new(:col1, "Column 1"),
        Tabloid::ReportColumn.new(:col2, "Column 2")
    ]
  end
  let(:row1) { Tabloid::Row.new(:columns => columns, :data => [1, 2]) }
  let(:row2) { Tabloid::Row.new(:columns => columns, :data => [3, 4]) }
  let(:group) { Tabloid::Group.new(:rows =>[row1, row2], :columns => columns, :label => "foobar") }

  it "has a label" do
    group.label.should == "foobar"
  end

  describe "producing output" do
    describe "as CSV" do
      it "includes all rows for the group" do
        rows = FasterCSV.parse(group.to_csv)
        rows.count.should == 2
        rows.should include(["1", "2"])
        rows.should include(["3", "4"])
      end
    end
    describe "as html" do
      let(:doc) { doc = Nokogiri::HTML(group.to_html)
      }
      it "creates a table row for each data row" do
        (doc/"tr[class='data']").count.should == 2
      end

      it "includes a label row" do
        (doc/"tr[class = 'group_header']")[0].text.should == "foobar"
      end
      it "doesn't include a label row when label is false" do
        group = Tabloid::Group.new(:rows =>[row1, row2], :columns => columns, :label => false)
        doc = Nokogiri::HTML(group.to_html)
        (doc/"tr[class='group_header']").count.should == 0
      end
    end
    context "with totals enabled" do
      describe "#rows" do
        it "includes a total row" do
          columns     = [
              Tabloid::ReportColumn.new(:col1, "Column 1", :total => true),
              Tabloid::ReportColumn.new(:col2, "Column 2", :total => true)
          ]
          total_group = Tabloid::Group.new(:rows =>[row1, row2], :columns => columns, :with_total => true)
          rows        = total_group.rows
          rows.count.should == 3
          rows.last[:col1].should == 4
          rows.last[:col2].should == 6
        end
      end
    end
  end
end
