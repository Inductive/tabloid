module Tabloid
  class Data
    attr_accessor :columns
    attr_accessor :rows

    def initialize(options = {})
      self.columns = options[:columns]
      self.rows = options[:rows]
    end

    def to_json
      rows.to_json
    end
  end
end