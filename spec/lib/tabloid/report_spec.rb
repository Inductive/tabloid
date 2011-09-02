require "spec_helper"
require 'fastercsv'

describe Tabloid::Report do

  context "producing output" do
    class CsvReport
      DATA=[
            [1, 2],
            [3, 4]
        ]
      include Tabloid::Report
      element :col1
      element :col2

      cache_key{'report'}

      rows do
        CsvReport::DATA
      end
    end

    before do
      @report = CsvReport.new
    end

    context "with memcached caching" do
      before do
        Tabloid.cache_engine = :memcached
        Tabloid.cache_connection_options = {
            :server => "localhost",
            :port => "11211"
        }
      end
      after do
        Tabloid.cache_engine = nil
      end

      describe "#data" do
        it "should cache after collecting the data" do
          Dalli::Client.any_instance.stub(:get).and_return(nil)
          Dalli::Client.any_instance.stub(:set).and_return(false)
          Dalli::Client.any_instance.should_receive(:set).with('report', CsvReport::DATA.to_json).and_return(true)
          @report.data
        end

        it "should return the cached data if it exists" do
          Dalli::Client.any_instance.stub(:get).with('report').and_return(CsvReport::DATA.to_json)
          Dalli::Client.any_instance.stub(:set).and_return(true)

          @report.data.rows.should == CsvReport::DATA
        end
      end
    end

    describe "#to_csv" do
      it "includes headers by default" do
        csv_output = FasterCSV.parse(@report.to_csv)
        headers    = csv_output.first
        headers.first.should match(/col1/)
        headers.last.should match(/col2/)
      end
      it "excludes headers upon request" do
        @report.to_csv(:headers => false).should_not match(/col1.*col2/)
      end

      it "includes the data from the report" do
        csv_output = FasterCSV.parse(@report.to_csv)
        csv_output[1].should == ['1', '2']
        csv_output[2].should == ['3', '4']
      end
    end

    describe "#to_html" do
      it "works" do
        @report.to_html.should_not be_nil
      end
    end
  end


  describe "#element" do
    class ElementTestReport
      include Tabloid::Report
      element :col1
    end

    before do
      @report = DataTestReport.new
    end

    it "adds a column to the report data" do
      @report.columns[:col1].should_not be_nil
    end
  end

  describe "#parameter" do
    class ParameterTestReport
      include Tabloid::Report
      parameter :test_param
      rows do
        [[parameter(:test_param)]]
      end
    end
    it "requires a parameter in the initializer" do
      expect{ ParameterTestReport.new.prepare}.should raise_error(Tabloid::MissingParameterError, "Must supply :test_param when creating the report")
    end

    it "makes the parameter available in the report" do
      report = ParameterTestReport.new.prepare(:test_param => "supercalifragilisticexpialidocious")
      report.to_html.should match(/supercalifragilisticexpialidocious/)
    end
  end

  describe "#data" do
    class DataTestReport
      include Tabloid::Report
      element :col1
      element :col2
      rows do
        [OpenStruct.new(:col1 => 1, :col2 => 2)]
      end
    end
    it "has columns" do
      report = DataTestReport.new
      report.columns.should_not be_nil
    end

    it "can look up columns in rows by key" do
      report = DataTestReport.new
      report.data.rows.should include([1,2])
    end

  end
end

