module Tabloid
  class Data
    attr_accessor :report_columns
    attr_reader :rows

    def initialize(options = {})
      raise ArgumentError.new("Must supply row data") unless options[:rows]
      raise ArgumentError.new("Must supply column data") unless options[:report_columns]

      @report_columns = options[:report_columns]
      @grouping_key     = options[:grouping_key] || :default
      @grouping_options = options[:grouping_options] || {:total => true}

      @rows = convert_rows(options[:rows])

    end

    def to_csv
      header_csv + rows.map(&:to_csv).join
    end

    def to_html
      header_html + rows.map(&:to_html).join
    end

    private
    def convert_rows(rows)
      rows.map! do |row|
        Tabloid::Row.new(:columns => @report_columns, :data => row)
      end

      if @grouping_key
        rows = rows.group_by { |r| r[@grouping_key] }
      else
        rows = {:default => rows}
      end

      rows.keys.map do |key|
        data_rows = rows[key]

        label = (key == :default ? false : key)
        Tabloid::Group.new :columns => @report_columns, :rows => data_rows, :label => label, :total => @grouping_options[:total]
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
          tr.th(col.to_header, "class" => col.key) unless col.hidden?
        end
      end
    end
  end
end