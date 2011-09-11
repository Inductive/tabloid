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
        val = value_for_key(col, index)
        csv_array << val
      end
      csv << csv_array
    end
  end

  def to_html
    html = Builder::XmlMarkup.new
    html.tr("class" => "data") do |tr|
      @columns.each_with_index do |col, index|
        next if col.hidden?
        tr.td(value_for_key(col, index), "class" => col.key)
      end
    end
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
      @data.send(key)
    end
  end

  def method_missing(method, *args)
    if @columns.detect{|col| col.key == method}
      self[method]
    else
      super
    end
  end

  private
  def value_for_key(col, index)
    if @data.is_a? Array
      @data[index]
    else
      @data[col.key]
    end
  end

end