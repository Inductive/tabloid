require "spec_helper"

describe Tabloid::CardinalityRow do
  context "[formatting]" do

    class Formatter
      def format_for_value(value)
        "Formatted value #{value}"
      end

      def format_for_value_and_row(value, row)
        "Value #{value}, Row #{row.join " "}"
      end

      def format_row_html(value)
        "<p>#{value}</p>"
      end
    end

    let(:columns) do
      [Tabloid::ReportColumn.new(:col1, "Column 1", :formatter => :format_for_value, :formatting_by => Formatter.new)]
    end
    let(:row) { Tabloid::CardinalityRow.new :columns => columns, :data => ['cell data'] }

    context "[csv]" do
      it "ignores formatting" do
        csv_row = FasterCSV.parse(row.to_csv).first
        csv_row.should == ['cell data']
      end
    end
    context "[html]" do
      it "ignores formatting" do
        doc = Nokogiri::HTML row.to_html
        (doc / "td[class='col1']").first.children.last.text.should == 'cell data'
      end
    end
  end
end
