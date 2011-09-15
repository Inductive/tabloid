class Tabloid::HeaderRow
  def initialize(text, options={})
    @text = text
    @options = options
  end

  def to_csv
    FasterCSV.generate{|csv| csv << to_a}
  end

  def to_html(options={})
    html = Builder::XmlMarkup.new
    html.tr("class" => (options[:class] || "header")) do |tr|
      tr.td(@text, "colspan" => column_count)
    end
  end

  def to_a
    [@text].fill(nil, 1, column_count-1)
  end

  def summarize
    nil
  end

  private
  def column_count
    (@options[:column_count] || 1)
  end

end