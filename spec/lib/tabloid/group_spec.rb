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
    describe "#cardinality" do
      it "counts rows" do
        Tabloid::Group.new(:rows => [], :columns => columns).cardinality.should == 0
        Tabloid::Group.new(:rows => [row1], :columns => columns).cardinality.should == 1
        Tabloid::Group.new(:rows => [row1, row2], :columns => columns).cardinality.should == 2
      end
    end
    context "cardinality" do
      let(:columns) { [Tabloid::ReportColumn.new(:col1, "Column 1"), Tabloid::ReportColumn.new(:col2, "Column 2")] }
      let(:row1) { Tabloid::Row.new(:columns => columns, :data => [1, 2]) }
      let(:row2) { Tabloid::Row.new(:columns => columns, :data => [3, 4]) }
      it "adds cardinality info to a group label" do
        group = Tabloid::Group.new(:rows => [row1, row2], :columns => columns, :label => "foobar", :cardinality => 'foo')
        rows = FasterCSV.parse(group.to_csv)
        rows.first.should == ["foobar (2 foos)", nil]
      end
      it "shows cardinality even if a group label isn't provided'" do
        group = Tabloid::Group.new(:rows => [row1, row2], :columns => columns, :cardinality => 'foo')
        rows = FasterCSV.parse(group.to_csv)
        rows.first.should == ["2 foos", nil]
      end
      it "takes into account grammatical number" do
        group = Tabloid::Group.new(:rows => [row1], :columns => columns, :cardinality => 'foo')
        rows = FasterCSV.parse(group.to_csv)
        rows.first.should == ["1 foo", nil]
      end
    end
  end
end
