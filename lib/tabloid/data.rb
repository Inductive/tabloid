module Tabloid
  class Data
    attr_accessor :report_columns
    attr_accessor :rows

    def initialize(options = {})
      self.report_columns = options[:report_columns]
      self.rows = options[:rows]
    end

    def to_json
      rows.to_json
    end
  end
end