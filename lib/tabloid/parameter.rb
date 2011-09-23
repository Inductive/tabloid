module Tabloid
  class Parameter
    attr_accessor :key, :label
    def initialize(key, label = nil )
      self.key = key
      self.label = label || humanize(key.to_s)
    end

    private
    def humanize(string)
      "#{string.first.upcase}#{string[1..-1]}".gsub("_", " ")
    end

  end
end