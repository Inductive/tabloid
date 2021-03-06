class Tabloid::Row
  def initialize(*args)
    options = args.pop
    if args.first
      @data = args.first
    else
      @data = options[:data]
    end
    raise "Must supply data to .new when creating a new Row" unless @data

    @columns = options[:columns]
    raise "Must supply column information when creating a new Row" unless @columns
  end


  def to_csv
    FasterCSV.generate do |csv|
      csv_array = []
      @columns.each_with_index do |col, index|
        next if col.hidden?
        csv_array << column_value(col)
      end
      csv << csv_array
    end
  end

  def to_html(options = {})
    html = Builder::XmlMarkup.new
    html.tr("class" => (options[:class] || "data")) do |tr|
      @columns.each_with_index do |col, index|
        unless col.hidden?
          if col.html[:row]
            tr.td("class" => col.key) { |td| td << column_value(col).to_s }
          else
            tr.td(column_value(col), "class" => col.key)
          end
        end
      end
    end
  end

  def summarize(key, &block)
    self[key]
  end

  def [](key)
    if @data.is_a? Array
      if key.is_a? Numeric
        @data[key]
      else
        index = @columns.index{|col| col.key == key}
        @data[index]
      end
    else
      if key.is_a? Numeric
        key = @columns[key].key
      end
      @data.send(key)
    end
  end

  def column_value(col)
    if col.with_format?
      value_with_format self[col.key], col
    else
      self[col.key]
    end
  end

  def value_with_format(value, col)
    col.format value, @data.dup
  end


  def method_missing(method, *args)
    if @columns.detect{|col| col.key == method}
      self[method]
    else
      super
    end
  end

end
