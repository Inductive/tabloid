require "spec_helper"

describe Tabloid::Data do
  let(:columns) do
    [
        Tabloid::ReportColumn.new(:col1, "Column 1"),
        Tabloid::ReportColumn.new(:col2, "Column 2")
    ]
  end
  let(:rows) { [[1, 2], [3, 4]] }
  describe "creation" do
    it "works when rows and columns are provided" do
      lambda { Tabloid::Data.new(:report_columns => columns, :rows => rows) }.should_not raise_error(ArgumentError)

    end
    it "requires row data" do
      lambda { Tabloid::Data.new(:report_columns => columns) }.should raise_error(ArgumentError, "Must supply row data")
    end
    it "requires column data" do
      lambda { Tabloid::Data.new(:rows => rows) }.should raise_error(ArgumentError, "Must supply column data")
    end

    it "puts rows into groups" do
      data = Tabloid::Data.new(:report_columns => columns, :rows => rows, :grouping => :col1)
      data.rows.first.should be_a(Tabloid::Group)
    end
  end
end