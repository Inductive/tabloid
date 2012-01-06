class Tabloid::Group

  attr_reader :rows
  attr_reader :columns
  attr_reader :label

  def initialize(options)
    @rows                 = options[:rows]
    @columns              = options[:columns]
    @visible_column_count = @columns.count { |col| !col.hidden? }
    @total_required       = options[:total]
    @cardinality_required = !options[:cardinality].nil?
    @cardinality_label    = options[:cardinality]
    @label                = options[:label]
    raise ArgumentError.new("Must supply row data to a Group") unless @rows
  end

  def total_required?
    !!@total_required
  end

  def rows
    result = @rows.dup

    if total_required?
      summed_data = columns.map { |col| col.total? ? sum_rows(col.key) : nil }
      result.push Tabloid::Row.new(:data => summed_data, :columns => self.columns)
    end

    if @cardinality_required
      cardinality_data = [(@cardinality_label || "Cardinality"), @rows.size]
      (@visible_column_count.size - 2).times { cardinality_data.push nil }
      result.push Tabloid::Row.new(:data => cardinality_data, :columns => self.columns)
    end

    result
  end

  def summarize(key, &block)
    @rows[1..-1].inject(@rows[0].send(key)){|summary, row| block.call(summary, row.send(key))  }
  end

  def to_csv
    header_row_csv + rows.map(&:to_csv).join
  end

  def to_html
    header_row_html + rows.map(&:to_html).join
  end

  private
  def sum_rows(key)
    #use the initial value from the same set of addends to prevent type conflict
    #like 0:Fixnum + 0:Money => Exception
    return unless @rows && @rows.any?
    @rows[1..-1].inject(@rows[0][key]) { |sum, row| sum + row[key] }
  end

  def header_row_csv
    if @label
      cols = [label]
      (@visible_column_count-1).times{ cols << nil}
      FasterCSV.generate{|csv| csv<<cols}
    else
      ""
    end
  end

  def header_row_html
    if @label
      html = Builder::XmlMarkup.new
      html.tr(:class => "group_header") do |tr|
        tr.td(label, {"colspan" => @visible_column_count})
      end
    else
      ""
    end
  end
end
