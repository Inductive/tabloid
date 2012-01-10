class Tabloid::Group

  attr_reader :rows
  attr_reader :columns
  attr_reader :label

  def initialize(options)
    @rows                 = options[:rows]
    @columns              = options[:columns]
    @visible_column_count = @columns.count { |col| !col.hidden? }
    @total_required       = !!options[:total]
    @cardinality_required = !!options[:cardinality]
    @cardinality_label    = options[:cardinality] || "Cardinality"
    @label                = options[:label]
    raise ArgumentError.new("Must supply row data to a Group") unless @rows
  end

  def rows
    @rows.dup + total_rows + cardinality_rows
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

  def total_rows
    return [] unless @total_required

    summed_data = columns.map { |col| col.total? ? sum_rows(col.key) : nil }
    [Tabloid::Row.new(:data => summed_data, :columns => self.columns)]
  end

  def cardinality_rows
    [].tap do |result|
      if @cardinality_required
        empty_cells = (@visible_column_count.size - 2).times.map { nil }
        cardinality_data = [@cardinality_label, @rows.size, *empty_cells]
        result.push Tabloid::CardinalityRow.new(:data => cardinality_data, :columns => self.columns)
      end
    end
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
