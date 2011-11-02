module Tabloid
  class ReportColumn
    attr_accessor :key
    attr_accessor :label
    attr_accessor :hidden
    attr_accessor :formatter

    class FormatterArityError < RuntimeError; end

    def initialize(key, label = "", options={})
      self.key = key
      self.label = label
      @hidden =  options[:hidden]
      @total = options[:total]
      @formatter = options[:formatter]

      if @formatter && @formatter.arity != 1 && @formatter.arity != 2
        raise FormatterArityError
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
      @formatter && @formatter.class == Proc
    end

    def to_header
      return self.label if label
      self.key
    end
  end
end
