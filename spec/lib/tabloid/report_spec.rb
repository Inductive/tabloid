require "spec_helper"

describe Tabloid::Report do

  context "producing output" do
    class CsvReport
      DATA=[
            [1, 2],
            [3, 4]
        ]
      include Tabloid::Report

      parameter :param1, "TestParameter"

      element :col1, 'Col1'
      element :col2, 'Col2'

      cache_key{'report'}

      rows do
        CsvReport::DATA
      end

      def name
        "Report"
      end
    end

    before do
      @report = CsvReport.new
      @report.prepare(:param1 => "foobar")
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
          client_stub = Dalli::Client.new("localhost:11211")
          client_stub.stub(:get).and_return(nil)
          client_stub.should_receive(:set).with('report', anything).and_return(true)
          Dalli::Client.stub(:new).and_return(client_stub)

          @report.data
        end

        it "should return the cached data if it exists" do
          client_stub = Dalli::Client.new("localhost:11211")
          client_stub.stub(:get).with('report').and_return(YAML.dump(@report.data))
          client_stub.stub(:set).and_return(true)
          Dalli::Client.stub(:new).and_return(client_stub)

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

      it "includes parameter information" do
        pending("Need to put parameter block in the report")
        (doc/".parameter_label").text.should include("TestParameter")
        (doc/".parameter_value").text.should include("foobar")
      end
    end

    describe "#to_pdf" do
      it "should work" do
        @report.to_pdf.should_not be_nil
        @report.to_pdf.should_not be_empty
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

  end

  context "[formatting]" do
    context "with memcached caching" do
      before do
        #Tabloid.cache_engine = :memcached
        Tabloid.cache_engine = :redis
        @report = FormattingTestReport.new
      end
      after do
        Tabloid.cache_engine = nil
      end

      class FormattingTestReport
        include Tabloid::Report

        class Formatter
          def simple_format(value)
            "Value is #{value}"
          end
        end

        formatting_by Formatter.new
        element :col1, "Column 1", :formatter => :simple_format
        element :col2, "Column 2", :formatter => :simple_format, :formatting_by => Formatter.new
        cache_key { "test-#{Time.now.to_i}" }
        rows { [[1, 2]] }
      end

      it "adds a column to the report data" do
        csv = FasterCSV.parse(@report.to_csv)
        csv.to_a.should == [["Column 1", "Column 2"], ["Value is 1", "Value is 2"]]
      end
    end
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
      cache_key {"key"}

      element :col1, "Column 1"
      rows do
        [[parameter(:test_param)]]
      end
    end

    it "requires a parameter in the initializer" do
      expect{ ParameterTestReport.new.prepare}.should raise_error(Tabloid::MissingParameterError, "Must supply :test_param when creating the report")
    end

    it "should allow 'false' value for parameters" do
      expect{ ParameterTestReport.new.prepare(:test_param => false)}.should_not raise_error(Tabloid::MissingParameterError)
    end

    it "makes the parameter available in the report" do
      report = ParameterTestReport.new.prepare(:test_param => "supercalifragilisticexpialidocious")
      report.to_html.should match(/supercalifragilisticexpialidocious/)
    end
  end

end

