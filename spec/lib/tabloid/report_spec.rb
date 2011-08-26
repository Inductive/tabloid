require "spec_helper"

describe Tabloid::Report do
  class RowTestReport
    RowData = [1,2,3]

    include Tabloid::Report

    report do
      rows do
        [[1],[2]]
      end
    end
  end

  context "without grouping" do
    describe "#data" do
      subject { RowTestReport.new }

      it("is an array of rows") do
        subject.data.should be_a Array
        subject.data.first.should be_a Array
      end

      it("should match the source row data") do
        subject.data.should == [[1],[2]]
      end
    end
  end


end

