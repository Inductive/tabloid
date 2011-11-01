module Tabloid
  class ReportColumn
    attr_accessor :key
    attr_accessor :label
    attr_accessor :hidden

    def initialize(key, label = "", options={})
      self.key = key
      self.label = label
      @hidden =  options[:hidden]
      @total = options[:total]
      @formatter = options[:formatter]
    end

    def to_s
      @key.to_s
    end

    def total?
      @total
    end

    def hidden?
      hidden
    end

    def formated?
      @formatter && @formatter.class == Proc
    end

    def to_header
      return self.label if label
      self.key
    end

    def format(val)
      @formatter ? @formatter.call(val) : val
    end
  end
end
