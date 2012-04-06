require 'pdfkit'

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
      set_parameter Tabloid::Parameter.new(*args)
    end
    
    def set_parameter(param)
      @report_parameters = [] if @report_parameters.nil?
      @report_parameters << param
    end

    def store_parameters(attribute)

    end

    def parameters
      @report_parameters
    end

    def summary(summary_options = {})
      @summary_options = summary_options
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

    def element(key, label = "", options={})
      updated_options = options.dup
      updated_options.update(:formatting_by => @formatting_by) if options[:formatting_by].nil?
      set_element Tabloid::ReportColumn.new(key, label, updated_options)
    end
    
    def set_element(elem)
      if @report_columns.nil?
        @report_columns    = []
        @report_columns.extend Tabloid::ColumnExtensions
      end
      @report_columns << elem
    end

    def formatting_by(obj)
      @formatting_by = obj
    end

    def grouping(key, options = {})
      @grouping_key     = key
      @grouping_options = options
    end

    def grouping_key
      @grouping_key
    end

    def grouping_options
      @grouping_options
    end

    def summary_options
      @summary_options
    end
  end

  module InstanceMethods

    HTML_FRAME =<<-EOS
      <html>
        <header>
        </header>
        <body>
          <h1>%s</h1>
          <h1>%s</h1>
          <div id='report'>
            %s
          </div>
        </body>
      </html>
    EOS

    def prepare(options={})
      before_prepare if self.respond_to?(:before_prepare)
      @report_parameters = {}
      parameters.each do |param|
        value = options.delete param.key
        raise Tabloid::MissingParameterError.new("Must supply :#{param.key} when creating the report") if value.nil?
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
      load_from_cache if Tabloid.cache_enabled?
      @report_parameters[key] if @report_parameters
    end

    def data
      load_from_cache if Tabloid.cache_enabled?
      build_and_cache_data
      @data
    end

    def to_html
      table_string = "<table id='#{generate_html_id}_table'>#{data.to_html}</table>"
      parameter_info_html + table_string
    end

    def to_csv
      csv_result = FasterCSV.generate do |csv|
        csv << [self.provider.name]
        formatted_parameters.to_a.each{ |report_param| csv << report_param }
        csv << []
      end
      csv_result + data.to_csv
    end

    def to_pdf
      kit = PDFKit.new(to_complete_html)
      kit.stylesheets << File.expand_path("../../static/report.pdf.css", File.dirname(__FILE__))
      kit.to_pdf
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

    def to_complete_html
      HTML_FRAME % [self.name, self.provider.name, self.to_html]
    end

    def cache_data(data)
      if Tabloid.cache_enabled?
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
      if Tabloid.cache_enabled? && !@cached_data
        @cached_data = read_from_cache
        if @cached_data
          @cached_data        = YAML.load(@cached_data)
          @data              = @cached_data[:data]
          @report_parameters = @cached_data[:parameters]
        end
      end
    end


    def cache_client
      if Tabloid.cache_enabled?
        server = Tabloid.cache_connection_options[:server] || 'localhost'
        if Tabloid.cache_engine == :memcached
          port          = Tabloid.cache_connection_options[:port] || '11211'
          @cache_client ||= Dalli::Client.new("#{server}:#{port}")
        elsif Tabloid.cache_engine == :redis
          port          = Tabloid.cache_connection_options[:port] || '6379'
          @cache_client ||= Redis.new(
              :host => server,
              :port => port)
        end
      end
    end

    def build_and_cache_data
      @data ||= begin
        report_data = Tabloid::Data.new(
            :report_columns   => self.report_columns,
            :rows             => prepare_data,
            :grouping_key     => grouping_key,
            :grouping_options => grouping_options,
            :summary          => summary_options
        )
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
      cache_client.get(cache_key) if cache_client && cache_key
    end

    def grouping_options
      self.class.grouping_options
    end

    def grouping_key
      self.class.grouping_key
    end

    def summary_options
      self.class.summary_options
    end

    def parameter_info_html
      html = Builder::XmlMarkup.new
      html = html.p("id" => "parameters") do |p|
        formatted_parameters.each do |param|
          p.div do |div|
            div.span(param[0], "class" => "parameter_label")
            div.span(param[1], "class" => "parameter_value", "style" => "padding-left: 10px;")
          end
        end
      end
      html.to_s
    end
    
    def formatted_parameters
      displayed_parameters.map{ |param| [param.label, format_parameter(param)] }
    end

    def format_parameter(param)
      parameter(param.key)
    end

    def displayed_parameters
      params = self.parameters.select { |param| displayed?(param) }
      params
    end
    
    def displayed?(param)
      true
    end

    def generate_html_id
      class_name = self.class.to_s
      class_name.gsub!(/::/, '-')
      class_name.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
      class_name.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
      class_name.downcase!
    end
  end
end
