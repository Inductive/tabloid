module Tabloid
  module ColumnExtensions
    def [](val)
      if val.is_a?(String) || val.is_a?(Symbol)
        self.detect { |c| c.key == val }
      else
        super
      end
    end
  end
end