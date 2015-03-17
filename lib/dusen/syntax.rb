# encoding: utf-8

module Dusen
  class Syntax

    def initialize
      @scopers = {}
    end

    def learn_field(field, &scoper)
      field = field.to_s
      @scopers[field] = scoper
    end

    def learn_unknown_field(&unknown_scoper)
      @unknown_scoper = unknown_scoper
    end

    def search(root_scope, query)
      query = parse(query) if query.is_a?(String)
      query = query.condensed
      matches = find_parsed_query(root_scope, query.positive)
      if query.negative.any?
        negative_matches = find_parsed_query(root_scope, query.negative)
        negative_ids = negative_matches.collect_ids
        column_name = Util.qualify_column_name(matches.origin_class, 'id')
        matches.scoped(:conditions => [column_name + " NOT IN (?)", negative_ids])
      else
        matches
      end
    end

    def fields
      @scopers
    end

    def parse(query)
      Parser.parse(query)
    end

    private

    DEFAULT_UNKNOWN_SCOPER = lambda do |scope, *args|
      if scope.respond_to?(:where)
        # Rails 3
        scope.where('1=2')
      else
        # Rails 2
        scope.scoped(:conditions => ['1=2'])
      end
    end

    def unknown_scoper
      @unknown_scoper || DEFAULT_UNKNOWN_SCOPER
    end

    def find_parsed_query(root_scope, tokens)
      scope = root_scope
      tokens.each do |token|
        scoper = @scopers[token.field] || unknown_scoper
        scope = scoper.call(scope, token.value)
      end
      scope
    end

  end
end
