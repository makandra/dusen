module Dusen
  class Parser

    WESTERNISH_WORD_CHARACTER =  '\\w\\-\\.@_ÄÖÜäöüß' # this is wrong on so many levels
    TEXT_QUERY = /(?:"([^"]+)"|([#{WESTERNISH_WORD_CHARACTER}]+))/
    FIELD_QUERY = /(\w+)\:#{TEXT_QUERY}/

    def self.parse(query_string)
      query_string = query_string.dup # we are going to delete substrings in-place
      query = Query.new
      extract_field_query_atoms(query_string, query)
      extract_text_query_atoms(query_string, query)
      query
    end

    def self.extract_text_query_atoms(query_string, query)
      while query_string.sub!(TEXT_QUERY, '')
        value = "#{$1}#{$2}"
        query << Atom.new(value)
      end
    end

    def self.extract_field_query_atoms(query_string, query)
      while query_string.sub!(FIELD_QUERY, '')
        field = $1
        value = "#{$2}#{$3}"
        query << Atom.new(field, value)
      end
    end

  end
end
