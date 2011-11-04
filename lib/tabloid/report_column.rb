module Tabloid
  class ReportColumn
    attr_accessor :key
    attr_accessor :label
    attr_accessor :hidden
    attr_accessor :formatter

    class FormatterError < RuntimeError; end

    def initialize(key, label = "", options={})
      self.key = key
      self.label = label
      @hidden =  options[:hidden]
      @total = options[:total]
      @formatter = options[:formatter]
      @formatting_by = options[:formatting_by]

      unless @formatter.nil?
        raise FormatterError, "formatter or formatting_by is not specified" unless @formatting_by
        raise FormatterError, "formatter method doesn't supported by formatting_by" unless @formatting_by.respond_to?(@formatter)

        method = @formatting_by.method(@formatter)
        raise FormatterError, "Incorrect formatter arity: #{method.arity}" unless method.arity == 1 || method.arity == 2
      end
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

    def with_format?
      @formatter && @formatting_by
    end

    def to_header
      return self.label if label
      self.key
    end

    def format(value, row)
      method = @formatting_by.method(@formatter)
      method.arity == 1 ? method.call(value) : method.call(value, row)
    end
  end
end
