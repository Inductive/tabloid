module Tabloid
  class Parameter
    attr_accessor :key, :label
    def initialize(key, label = nil )
      self.key = key
      self.label = label || humanize(key.to_s)
    end

    private
    def humanize(string)
      string.gsub!("_", " ")
      "#{string.first.upcase}#{string[1,-1]}"
    end

  end
end