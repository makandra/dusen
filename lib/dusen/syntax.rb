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
      exclude_scope_conditions = concatenate_where_values(exclude_scope.where_values)
      if exclude_scope_conditions.present?
        excluded_values = exclude_query.tokens.map(&:value).flatten
        inverted_sql = "NOT COALESCE (" + exclude_scope_conditions + ",0)"
        if inverted_sql.include?('?')
          exclude_scope.except(:where).where(inverted_sql, *excluded_values)
        else
          exclude_scope.except(:where).where(inverted_sql)
        end
      else
        # we cannot build an inverted scope without where-conditions

        root_scope
      end
    end

    def concatenate_where_values(where_values)
      if where_values.any?
        if where_values[0].is_a?(String)
          first = where_values.shift
          where = where_values.reduce(first) do |result, value|
            result << " AND " << value
          end
          where
        else
          # where_values are AREL-Nodes
          where = where_values.reduce(:and)
          where.to_sql
        end
      end
    end

  end
end
