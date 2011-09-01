module Tabloid
  class Column
    attr_accessor :key

    def initialize(*args)
      @key = args.first
    end

    def to_s
      @key.to_s
    end
  end
end