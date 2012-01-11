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
    @cardinality_label    = options[:cardinality]
    @label                = options[:label]
    raise ArgumentError.new("Must supply row data to a Group") unless @rows
  end

  def rows
    @rows.dup + total_rows
  end

  def cardinality
    @rows.size
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

  def header_row_csv
    return '' unless header_present?

    cols = [header_content]
    (@visible_column_count-1).times{ cols << nil}
    FasterCSV.generate{|csv| csv<<cols}
  end

  def header_row_html
    return '' unless header_present?

    html = Builder::XmlMarkup.new
    html.tr(:class => "group_header") do |tr|
      tr.td(header_content, {"colspan" => @visible_column_count})
    end
  end

  def header_present?
    @label || @cardinality_required
  end

  def header_content
    case [!!@label, !!@cardinality_required]
      when [true, true] then "#{@label} (#{cardinality_content})"
      when [true, false] then @label
      when [false, true] then cardinality_content
      else ''
    end
  end

  def cardinality_content
    label = if @rows.size > 1 && @cardinality_label
              "#{@cardinality_label}s"
            else
              @cardinality_label
            end

    [@rows.size, label].join ' '
  end
end
