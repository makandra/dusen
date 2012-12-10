require 'spec_helper'

describe Dusen::Query do

  describe '#condensed' do

    it 'should return a version of the query where all text tokens have been collapsed into a single token with an Array value' do
      query = Dusen::Parser.parse('field:value foo bar baz')
      query.tokens.size.should == 4
      condensed_query = query.condensed
      condensed_query.tokens.size.should == 2
      condensed_query[0].field.should == 'field'
      condensed_query[0].value.should == 'value'
      condensed_query[1].field.should == 'text'
      condensed_query[1].value.should == ['foo', 'bar', 'baz']
    end

  end

end
