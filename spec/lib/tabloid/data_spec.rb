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
      data = Tabloid::Data.new(:report_columns => columns, :rows => rows, :grouping_key => :col1)
      data.rows.first.should be_a(Tabloid::Group)
    end

    describe "summary" do
      context "[summary options is presented]" do
        let(:data){ Tabloid::Data.new(:report_columns => columns, :rows => rows, :summary => { :col2 => :sum } )}
        it "adds a totals row to the csv output" do
          csv_rows = FasterCSV.parse(data.to_csv)
          csv_rows.should include(["Totals", nil])
          csv_rows.should include([nil, "6"])
        end
        it "adds a totals row to the html output" do
          doc = Nokogiri::HTML(data.to_html)
          (doc/"tr.summary").should_not be_empty
          (doc/"tr.summary td.col2").text.should == "6"
        end
      end
      context "[summary options is not presented]" do
        let(:data) { Tabloid::Data.new(:report_columns => columns, :rows => rows ) }

        it "should not add total row to the csv output" do
          csv_rows = FasterCSV.parse(data.to_csv)
          csv_rows.flatten.should_not include("Totals")
        end

        it "should not add total row to the html output" do
          doc = Nokogiri::HTML(data.to_html)
          (doc/"tr.summary").should be_empty
        end
      end
      context "[summary and cardinality options is presented]" do
        let(:data) do
          Tabloid::Data.new(:report_columns => columns,
                            :rows => rows,
                            :summary => { :col2 => :sum },
                            :grouping_key => :col1,
                            :grouping_options => { :cardinality => 'foo' })
        end
        it "adds a totals row with cardinality info to the csv output" do
          csv_rows = FasterCSV.parse(data.to_csv)
          csv_rows.should include(["Totals (2 foos)", nil])
        end
      end
      context "[cardinality options is presented]" do
        let(:data) do
          Tabloid::Data.new(:report_columns => columns,
                            :rows => rows,
                            :grouping_key => :col1,
                            :grouping_options => { :cardinality => 'foo' })
        end
        it "adds cardinality to the total label of the csv output" do
          data = Tabloid::Data.new(:report_columns => columns,
                                   :rows => rows,
                                   :grouping_key => :col1,
                                   :grouping_options => { :cardinality => 'foo' })
          csv_rows = FasterCSV.parse(data.to_csv)
          csv_rows.should include(["Totals (2 foos)", nil])
        end
        it "takes into account grammatical number" do
          data = Tabloid::Data.new(:report_columns => columns,
                                   :rows => [[1, 2]],
                                   :grouping_key => :col1,
                                   :grouping_options => { :cardinality => 'foo' })
          csv_rows = FasterCSV.parse(data.to_csv)
          csv_rows.should include(["Totals (1 foo)", nil])
        end
      end
      context "[empty report]" do
        before do
          data = Tabloid::Data.new(:report_columns => columns, :rows => [], :summary => { :col2 => :sum } )
          @csv_rows = FasterCSV.parse(data.to_csv)
        end

        it "should add blank total value in csv output" do
          @csv_rows.should include(["Totals", nil])
        end

        it "should create add empty summary row in csv output" do
          @csv_rows.last.should == [nil, nil]
        end
      end
    end
  end
end
