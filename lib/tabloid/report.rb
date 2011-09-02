module Tabloid::Report

  def self.included(base)
    base.class_eval do
      @report_parameters = []
      extend Tabloid::Report::ClassMethods
      include Tabloid::Report::InstanceMethods
    end
  end

  module ClassMethods
    def parameter(*args)
      @report_parameters << Tabloid::Parameter.new(*args)
    end

    def parameters
      @report_parameters
    end

    def columns
      @columns
    end

    def cache_key(&block)
      if block
        @cache_block = block
      end
    end

    def cache_key_block
      @cache_block
    end

    def rows_block
      @rows_block
    end

    def report(*args, &block)
      yield block if block_given?
    end

    def rows(*args, &block)
      @rows_block = block
    end

    def element(*args, &block)
      unless @columns
        @columns = []
        @columns.extend Tabloid::ColumnExtensions
      end
      @columns << Tabloid::Column.new(args[0], args[1])
    end
  end

  module InstanceMethods
    def prepare(options={})
      @report_parameters = {}
      parameters.each do |param|
        value = options.delete param.key
        raise Tabloid::MissingParameterError.new("Must supply :#{param.key} when creating the report") unless value
        @report_parameters[param.key] = value
      end
      build_and_cache_data
      self
    end

    def columns
      self.class.columns
    end

    def parameters
      self.class.parameters
    end

    def parameter(key)
      @report_parameters[key]
    end

    def data
      load_from_cache if Tabloid.cache_enabled?
      build_and_cache_data
      @data
    end

    def to_html(options = {:headers => true})
      if options[:headers] && self.columns
        column_names = self.columns.map(&:label)
      else
        column_names = nil
      end

      report_table = Ruport::Data::Table.new(:data => data.rows, :column_names =>column_names)
      report_table.to_html
    end

    def to_csv(options={:headers => true})
      if options[:headers]
        column_names = self.columns.map(&:label)
      else
        column_names = nil
      end

      report_table = Ruport::Data::Table.new(:data => data.rows, :column_names =>column_names)
      report_table.to_csv
    end

    def cache_key
      @key ||= begin
        if self.class.cache_key_block
          self.instance_exec &self.class.cache_key_block
        else
          nil
        end
      end
    end


    private
    def cache_data(data)
      if Tabloid.cache_engine == :memcached
        raise LocalJumpError.new("Must supply a cache_key block when caching is enabled") unless self.class.cache_key_block

        raise "Unable to cache data" unless cache_client.set(cache_key, data.to_json)

      end
      data
    end

    def cache_client
      if Tabloid.cache_engine == :memcached
        @cache_client ||= Dalli::Client.new("#{Tabloid.cache_connection_options['server'] || 'localhost'}:#{Tabloid.cache_connection_options['port']||'11211'}")
      end
    end

    def build_and_cache_data
      @data ||= begin
        report_data = Tabloid::Data.new(:columns => self.columns, :rows => prepare_data)
        cache_data( report_data.rows)
        report_data
      end
    end

    def load_from_cache
      if Tabloid.cache_enabled?
        cached_data = read_from_cache
        if cached_data
          @data = Tabloid::Data.new :columns => self.columns, :rows => JSON.parse(cached_data)
        end
      end

    end

    def prepare_data
      row_data = instance_exec(&self.class.rows_block)
      unless row_data.first.is_a? Array
        row_data.map! do |row|
          columns.map do |col|
            row.send(col.key)
          end
        end
      end
      row_data
    end

    def read_from_cache
      cache_client.get(cache_key) if cache_client
    end

  end
end