module Tabloid::Report

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      include Tabloid::Report::InstanceMethods
    end
  end

  module ClassMethods

    def rows_block
      @rows_block
    end

    def report(*args, &block)
      yield block if block_given?
    end

    def rows(*args, &block)
      @rows_block = block
    end
  end
  module InstanceMethods
    def data
      instance_exec  &self.class.rows_block
    end
  end
end