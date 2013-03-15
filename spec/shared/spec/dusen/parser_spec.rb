require 'spec_helper'

describe Dusen::Parser do

  describe '.parse' do

    it 'should parse field tokens first, because they usually give maximum filtering at little cost' do
      query = Dusen::Parser.parse('word1 field1:field1-value word2 field2:field2-value')
      query.collect(&:value).should == ['field1-value', 'field2-value', 'word1', 'word2']
    end

    it 'should not consider the dash to be a word boundary' do
      query = Dusen::Parser.parse('Baden-Baden')
      query.collect(&:value).should == ['Baden-Baden']
    end

  end

end
