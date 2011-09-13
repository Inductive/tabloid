require "spec_helper"

describe Tabloid::Report do

  context "producing output" do
    class CsvReport
      DATA=[
            [1, 2],
            [3, 4]
        ]
      include Tabloid::Report
      element :col1, 'Col1'
      element :col2, 'Col2'

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
        dc = Dalli::Client.new
        dc.set("report", nil)
        Tabloid.cache_engine = nil
      end

      describe "#data" do
        it "should cache after collecting the data" do
          #Dalli::Client.any_instance.stub(:get).and_return(nil)
          #Dalli::Client.any_instance.should_receive(:set).with('report', anything).and_return(true)
          @report.data
        end

        it "should cache the report parameters along with the data"

        it "should return the cached data if it exists" do
          #Dalli::Client.any_instance.stub(:get).with('report').and_return(YAML.dump(@report.data))
          #Dalli::Client.any_instance.stub(:set).and_return(true)

          @report.data.rows.should_not be_nil
        end
      end
    end

    describe "#to_csv" do
      it "includes headers by default" do
        csv_output = FasterCSV.parse(@report.to_csv)
        headers    = csv_output.first
        headers.first.should match(/Col1/)
        headers.last.should match(/Col2/)
      end

      it "includes the data from the report" do
        csv_output = FasterCSV.parse(@report.to_csv)
        csv_output.should include( ['1', '2'])
        csv_output.should include( ['3', '4'])
      end
    end

    describe "#to_html" do
      let(:doc){Nokogiri::HTML(@report.to_html)}
      it "creates a table" do
        (doc/"table").count.should == 1
      end
    end
  end


  describe "#element" do
    class ElementTestReport
      include Tabloid::Report
      element :col1
      rows do
        [[1,2]]
      end
    end

    before do
      @report = ElementTestReport.new
    end

    it "adds a column to the report data" do
      @report.data.report_columns[:col1].should_not be_nil
      @report.data.report_columns[0].key.to_s.should == "col1"
    end

    it ""

  end

  describe "grouping" do
    class GroupingTest
      include Tabloid::Report
      element :col1, "Col 1"
      element :col2, "Col 2"
      grouping :col1

      rows do
        [
            [1,2,3],
            [1,4,5]
        ]
      end
    end

    it "groups data by column specified" do
      report = GroupingTest.new
      data = FasterCSV.parse(report.to_csv)
      data.should include(['1',nil])
    end
  end

  describe "#parameter" do
    class ParameterTestReport
      attr_accessor :parameter_stash

      include Tabloid::Report
      parameter :test_param
      store_parameters :parameter_stash

      element :col1, "Column 1"
      rows do
        [[parameter(:test_param)]]
      end

    end
    it "requires a parameter in the initializer" do
      expect{ ParameterTestReport.new.prepare}.should raise_error(Tabloid::MissingParameterError, "Must supply :test_param when creating the report")
    end

    it "serializes the parameters when #store_parameters is used" do
      report = ParameterTestReport.new
      report.prepare(:test_param => "test")
      report.parameter_stash[:test_param].should == "test"
    end

    it "makes the parameter available in the report" do
      report = ParameterTestReport.new.prepare(:test_param => "supercalifragilisticexpialidocious")
      report.to_html.should match(/supercalifragilisticexpialidocious/)
    end
  end

end

