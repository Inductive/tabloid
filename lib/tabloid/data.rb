module Tabloid
  class Data
    attr_accessor :report_columns
    attr_reader :rows

    def initialize(options = {})
      raise ArgumentError.new("Must supply row data") unless options[:rows]
      raise ArgumentError.new("Must supply column data") unless options[:report_columns]

      @report_columns = options[:report_columns]
      @grouping       = options[:grouping]
      @rows           = convert_rows(options[:rows])

    end

    def to_csv
      header_csv + rows.map(&:to_csv).join
    end

    def to_html
      header_html + rows.map(&:to_html).join
    end

    private
    def convert_rows(rows)
      #TODO: convert rows to Row objects before grouping
      rows.map! do |row|
        Tabloid::Row.new(:columns => @report_columns, :data => row)
      end

      if @grouping
        rows = rows.group_by { |r| r[@grouping] }
      else
        rows = {:default => rows}
      end

      rows.keys.map do |key|
        data_rows = rows[key]

        label = (key == :default ? false : key)
        Tabloid::Group.new :columns => @report_columns, :rows => data_rows, :label => label
      end
    end

    def header_csv
      FasterCSV.generate do |csv|
        csv << @report_columns.map(&:to_header)
      end
    end

    def header_html
      headers = Builder::XmlMarkup.new
      headers.tr do |tr|
        @report_columns.each do |col|
          tr.th(col.to_header, "class" => col.key)
        end
      end
    end
  end
end