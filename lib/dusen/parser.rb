# encoding: utf-8

module Dusen
  class Parser

    WESTERNISH_WORD_CHARACTER =  '\\w\\-\\.;@_ÄÖÜäöüß' # this is wrong on so many levels
    TEXT_QUERY = /(?:(\-)?"([^"]+)"|(\-)?([#{WESTERNISH_WORD_CHARACTER}]+))/
    FIELD_QUERY = /(\-)?(\w+)\:#{TEXT_QUERY}/

    def self.parse(query_string)
      query_string = query_string.dup # we are going to delete substrings in-place
      query = Query.new
      extract_field_query_tokens(query_string, query)
      extract_text_query_tokens(query_string, query)
      query
    end

    def self.extract_text_query_tokens(query_string, query)
      while query_string.sub!(TEXT_QUERY, '')
        value = "#{$2}#{$4}"
        exclude = "#{$1}#{$3}" == "-"
        options = { :field => 'text', :value => value, :exclude => exclude }
        query << Token.new(options)
      end
    end

    def self.extract_field_query_tokens(query_string, query)
      while query_string.sub!(FIELD_QUERY, '')
        field = $2
        value = "#{$4}#{$6}"
        exclude = "#{$1}" == "-"
        options = { :field => field, :value => value, :exclude => exclude }
        query << Token.new(options)
      end
    end

  end
end
