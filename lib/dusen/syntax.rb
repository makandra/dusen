# encoding: utf-8

module Dusen
  class Syntax

    def initialize
      @scopers = {}
      learn_field(:text, &SEARCH_TEXT_SCOPER)
    end

    def learn_field(field, &scoper)
      field = field.to_s
      @scopers[field] = scoper
    end

    def learn_unknown_field(&unknown_scoper)
      @unknown_scoper = unknown_scoper
    end

    def search(root_scope, query)
      scope = root_scope
      query = parse(query) if query.is_a?(String)
      query = query.condensed
      query.each do |token|
        scoper = @scopers[token.field] || unknown_scoper
        scope = scoper.call(scope, token.value)
      end
      scope
    end

    def parse(query)
      Parser.parse(query)
    end

    private

    DEFAULT_UNKNOWN_SCOPER = lambda do |scope, *args|
      scope.where('1=2')
    end

    SEARCH_TEXT_SCOPER = lambda do |scope, phrases|
      Dusen::ActiveRecord::SearchText.match(scope, phrases)
    end

    def unknown_scoper
      @unknown_scoper || DEFAULT_UNKNOWN_SCOPER
    end

  end
end
