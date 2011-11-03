require "spec_helper"

describe Tabloid::ReportColumn do

  class Formatter
    def format_for_value(val)
      "Formatted value #{value}"
    end

    def format_for_value_and_row(value, row)
      "Value #{value}, Row #{row.join " "}"
    end

    def format_with_incorrect_arity
      ""
    end
  end

  describe "#initialize" do
    context "[invalid formatting options]"do
      it "should raise exception when missing formatting_by" do
        expect do
          Tabloid::ReportColumn.new(:col, "Column", :formatter => :format_for_value, :formatting_by => nil)
        end.should raise_error(Tabloid::ReportColumn::FormatterError, "formatter or formatting_by is not specified")
      end
      it "should raise exception when formatter is incorrect" do
        expect do
          Tabloid::ReportColumn.new(:col, "Column", :formatter => :incorrect_format, :formatting_by => Formatter.new)
        end.should raise_error(Tabloid::ReportColumn::FormatterError, "formatter method doesn't supported by formatting_by")
      end
    end
  end

  describe "#format" do
    it "should raise exception when formatter arity equal 0 or greater then 2" do
      expect do
        Tabloid::ReportColumn.new(:col, "Column", :formatter => :format_with_incorrect_arity, :formatting_by => Formatter.new)
      end.should raise_error(Tabloid::ReportColumn::FormatterError, "Incorrect formatter arity: 0")
    end
  end
end
