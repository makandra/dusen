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
      matches = find_parsed_query(root_scope, query.include)
      if query.exclude.any?
        inverted_exclude_scope = build_exclude_scope(root_scope, query.exclude)
        matches.merge(inverted_exclude_scope)
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

    def find_parsed_query(root_scope, query)
      scope = root_scope
      query.each do |token|
        scoper = @scopers[token.field] || unknown_scoper
        scope = scoper.call(scope, token.value)
      end
      scope
    end

    def build_exclude_scope(root_scope, exclude_query)
      root_scope_without_conditions = root_scope.except(:where)
      exclude_scope = find_parsed_query(root_scope_without_conditions, exclude_query)
      exclude_scope_conditions = exclude_scope.where_values.reduce(:and)
      if exclude_scope_conditions.present?
        # where_values.reduce(:and) returns a string if only one where_value given
        # and a Arel::Node for more than one where_value
        unless exclude_scope_conditions.is_a?(String)
          exclude_scope_conditions = exclude_scope_conditions.to_sql
        end
        inverted_sql = "NOT COALESCE (" + exclude_scope_conditions + ",0)"
        exclude_scope.except(:where).where(inverted_sql)
      else
        # we cannot build an inverted scope if no where-conditions are present
        root_scope
      end
    end

  end
end
