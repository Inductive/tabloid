class Tabloid::CardinalityRow < Tabloid::Row
  def column_value(col)
    self[col.key]
  end

end
