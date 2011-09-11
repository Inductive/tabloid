module Tabloid::Report

  def self.included(base)
    base.class_eval do
      @report_parameters = []
      @report_columns    = []
      @report_columns.extend Tabloid::ColumnExtensions
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

    def report_columns
      @report_columns
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

    def rows(*args, &block)
      @rows_block = block
    end

    def element(*args, &block)
      @report_columns << Tabloid::ReportColumn.new(args[0], args[1])
    end

    def grouping(*args)
      @grouping_options = args
    end

    def grouping_options
      @grouping_options
    end
  end

  module InstanceMethods

    def prepare(options={})
      before_prepare if self.respond_to?(:before_prepare)
      @report_parameters = {}
      parameters.each do |param|
        value = options.delete param.key
        raise Tabloid::MissingParameterError.new("Must supply :#{param.key} when creating the report") unless value
        @report_parameters[param.key] = value
      end
      data
      after_prepare if self.respond_to?(:after_prepare)

      self
    end

    def report_columns
      self.class.report_columns
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

    def to_html
      "<table>#{data.to_html}</table>"
    end

    def to_csv
      data.to_csv
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
        raise Tabloid::MissingParameterError.new("Must supply a cache_key block when caching is enabled") unless self.class.cache_key_block

        report_data = {
            :parameters => @report_parameters,
            :data       => data
        }

        raise "Unable to cache data" unless cache_client.set(cache_key, YAML.dump(report_data))

      end
      data
    end

    def load_from_cache
      if Tabloid.cache_enabled?
        cached_data = read_from_cache
        if cached_data
          cached_data        = YAML.load(cached_data)
          @data              = cached_data[:data]
          @report_parameters = cached_data[:parameters]
        end
      end
    end


    def cache_client
      if Tabloid.cache_enabled?
        @cache_client ||= Dalli::Client.new("#{Tabloid.cache_connection_options['server'] || 'localhost'}:#{Tabloid.cache_connection_options['port']||'11211'}")
      end
    end

    def build_and_cache_data
      @data ||= begin
        report_data = Tabloid::Data.new(:report_columns => self.report_columns, :rows => prepare_data, :grouping => grouping_options)
        cache_data(report_data)
        report_data
      end
    end


    def prepare_data
      row_data = instance_exec(&self.class.rows_block)
      #unless row_data.first.is_a? Array
      #  row_data.map! do |row|
      #    report_columns.map do |col|
      #      row.send(col.key).to_s
      #    end
      #  end
      #end
      row_data
    end

    def read_from_cache
      cache_client.get(cache_key) if cache_client
    end

    def grouping_options
      self.class.grouping_options
    end

  end
end