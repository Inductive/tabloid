module Tabloid
  class ReportColumn
    attr_accessor :key
    attr_accessor :label
    attr_accessor :hidden

    def initialize(*args)
      self.key = args.shift
      self.label = args.shift
      options = args.pop
      @hidden = true if options && options[:hidden]
      @total = options[:total] if options
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

    def to_header
      return self.label if label
      return self.key
    end
  end
end