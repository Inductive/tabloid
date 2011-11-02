require "spec_helper"

describe Tabloid::Row do
  let(:columns) { [
      Tabloid::ReportColumn.new(:col1, "Column 1", :hidden => true),
      Tabloid::ReportColumn.new(:col2, "Column 2")
  ] }
  let(:data) { [1, 2] }
  before do
    @row = Tabloid::Row.new(
        :columns => columns,
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
  context "with array data" do
    describe "accessing contents with []" do
      it "allows numeric access" do
        @row[0].should == 1
      end
      it "allows access by element key" do
        @row[:col1].should == 1
      end
    end
  end

  context "[formatting]" do
    context "[one argument]" do
      let(:columns) do
        [Tabloid::ReportColumn.new(:col1, "Column 1"),
         Tabloid::ReportColumn.new(:col2, "Column 2", :formatter => lambda { |value| "Formatted value #{value}" })]
      end

      it "should apply custom format to values for csv output format" do
        row = FasterCSV.parse(Tabloid::Row.new(:columns => columns, :data => [1, 2]).to_csv).first
        row.last.should == "Formatted value 2"
      end

      it "should apply custom format to values for csv output format" do
        doc = Nokogiri::HTML(Tabloid::Row.new(:columns => columns, :data => [1, 2]).to_html)
        (doc / "td[class='col2']").first.children.last.text.should == "Formatted value 2"
      end
    end

    context "[two arguments]" do
      let(:columns) do
        [Tabloid::ReportColumn.new(:col1, "Column 1"),
         Tabloid::ReportColumn.new(:col2, "Column 2", :formatter => lambda { |value, row| "Value #{value}, Row #{row.join " "}" })]
      end

      it "should can use row values for csv output format" do
        row = FasterCSV.parse(Tabloid::Row.new(:columns => columns, :data => [1, 2]).to_csv).first
        row.last.should == "Value 2, Row 1 2"
      end

      it "should apply custom format to values for csv output format" do
        doc = Nokogiri::HTML(Tabloid::Row.new(:columns => columns, :data => [1, 2]).to_html)
        (doc / "td[class='col2']").first.children.last.text.should == "Value 2, Row 1 2"
      end
    end

    context "[invalid arguments count]" do
      it "should raise exception when argument more then two" do
        expect do
          Tabloid::ReportColumn.new(:col2, "Column 2", :formatter => lambda { |value, row, invalid_argument| "Value" })
        end.should raise_error(Tabloid::ReportColumn::FormatterArityError)
      end

      it "should raise exception when there are no arguments" do
        expect do
          Tabloid::ReportColumn.new(:col2, "Column 2", :formatter => lambda { "Value" })
        end.should raise_error(Tabloid::ReportColumn::FormatterArityError)
      end
    end
  end

  context "with object data" do
    let(:data){OpenStruct.new({:col1 => 1, :col2 => 2})}
    let(:row) { Tabloid::Row.new(:columns => columns, :data => data) }
    describe "accessing contents with []" do
      it "allows numeric access" do
        row[0].should == 1
      end
      it "allows access by element key" do
        row[:col1].should == 1
      end
    end
  end
end
