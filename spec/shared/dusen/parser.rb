module Dusen
  module Parser

    describe '.parse' do

      it 'should parse field tokens first, because they usually give maximum filtering at little cost' do
        query = Dusen::Parser.parse('word1 field1:field1-value word2 field2:field2-value')
        query.collect(&:value).should == ['field1', 'field2', 'word1', 'word2']
      end

    end

  end
end
