require 'spec_helper'

describe Tabloid::Row do
  let(:header){Tabloid::HeaderRow.new("testtext", :column_count => 3)}
  it "has the correct number of columns" do
    header.to_a.should == ["testtext", nil, nil]
  end
end