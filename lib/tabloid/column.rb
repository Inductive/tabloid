module Tabloid
  class Column
    attr_accessor :key
    attr_accessor :label

    def initialize(*args)
      self.key = args[0]
      self.label = args[1]
    end

    def to_s
      @key.to_s
    end
  end
end