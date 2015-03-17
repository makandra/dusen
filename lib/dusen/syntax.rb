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
        exclude_matches = find_parsed_query(root_scope, query.exclude)

        # extract conditions that were added by exclude tokens
        sql = exclude_matches.to_sql
        root_pattern = /\A#{Regexp.quote root_scope.to_sql}/
        sql =~ root_pattern or raise "Could not find ..."
        sql = sql.sub(root_pattern, '')

        # negate conditions
        sql = sql.sub(/^\s*WHERE\s*/i, '')
        sql = sql.sub(/^\s*AND\s*/i, '')
        sql = "NOT COALESCE(#{sql}, 0)"

        matches.scoped(:conditions => sql)
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

  end
end
