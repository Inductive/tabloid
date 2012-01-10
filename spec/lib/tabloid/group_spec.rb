require "spec_helper"

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
  let(:anon_group) { Tabloid::Group.new(:rows =>[row1, row2], :columns => columns, :label => false) }

  it "has a label" do
    group.label.should == "foobar"
  end

  describe "producing output" do
    describe "as CSV" do
      let(:rows) { FasterCSV.parse(group.to_csv) }
      it "includes all rows for the group" do
        rows.should include(["1", "2"])
        rows.should include(["3", "4"])
      end
      it "includes a group label row" do
        rows.should include(["foobar", nil])
      end
      it "doesn't include a label row when label is falsey" do
        rows = FasterCSV.parse(anon_group.to_csv)
        rows.should_not include(["foobar", nil])
      end
    end
    describe "as html" do
      let(:doc) { doc = Nokogiri::HTML(group.to_html)
      }
      it "creates a table row for each data row" do
        (doc/"tr[class='data']").count.should == 2
      end

      it "includes a group label row" do
        (doc/"tr[class = 'group_header']")[0].text.should == "foobar"
      end
      it "doesn't include a label row when label is false" do
        doc = Nokogiri::HTML(anon_group.to_html)
        (doc/"tr[class='group_header']").count.should == 0
      end
    end

    describe "#summarize" do
      it "performs the supplied operation on the indicated column" do
        group.summarize(:col1, &:+).should == 4
        group.summarize(:col2, &:+).should == 6
      end
    end
    context "with totals enabled" do
      describe "#rows" do
        it "includes a total row" do
          columns     = [
              Tabloid::ReportColumn.new(:col1, "Column 1", :total => true),
              Tabloid::ReportColumn.new(:col2, "Column 2", :total => true)
          ]
          total_group = Tabloid::Group.new(:rows =>[row1, row2], :columns => columns, :total => true)
          rows        = total_group.rows
          rows.count.should == 3
          rows.last[:col1].should == 4
          rows.last[:col2].should == 6
        end
      end
    end
    context "cardinality" do
      describe "#rows" do
        it "includes a cardinality row" do
          columns     = [
              Tabloid::ReportColumn.new(:col1, "Column 1"),
              Tabloid::ReportColumn.new(:col2, "Column 2"),
              Tabloid::ReportColumn.new(:col3, "Column 3")
          ]
          group = Tabloid::Group.new(:rows =>[row1, row2], :columns => columns, :cardinality => 'Foos')
          cardinality_row = group.rows.last

          cardinality_row[:col1].should == "Foos"
          cardinality_row[:col2].should == 2
          cardinality_row[:col3].should be_nil
        end
        it "uses a default cardinality label"
      end
    end
  end
end
