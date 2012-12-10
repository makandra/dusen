# encoding: utf-8

module Dusen
  module Util
    extend self

    def like_expression(phrase)
      "%#{escape_for_like_query(phrase)}%"
    end

    def escape_with_backslash(phrase, characters)
      characters << '\\'
      pattern = /[#{characters.collect(&Regexp.method(:quote)).join('')}]/
      # debugger
      phrase.gsub(pattern) do |match|
        "\\#{match}"
      end
    end

    def escape_for_like_query(phrase)
      # phrase.gsub("%", "\\%").gsub("_", "\\_")
      escape_with_backslash(phrase, ['%', '_'])
    end

    def escape_for_boolean_fulltext_query(phrase)
      escape_with_backslash(phrase, ['+', '-', '<', '>', '(', ')', '~', '*', '"'])
    end

    def boolean_fulltext_query(phrases)
      phrases.collect do |word|
        escaped_word = Dusen::Util.escape_for_boolean_fulltext_query(word)
        if escaped_word =~ /\s/
          %{+"#{escaped_word}"} # no prefixed wildcard possible for phrases
        else
          %{+#{escaped_word}*}
        end
      end.join(' ')
    end

    def qualify_column_name(model, column_name)
      column_name = column_name.to_s
      unless column_name.include?('.')
        quoted_table_name = model.connection.quote_table_name(model.table_name)
        quoted_column_name = model.connection.quote_column_name(column_name)
        column_name = "#{quoted_table_name}.#{quoted_column_name}"
      end
      column_name
    end

    def append_scope_conditions(scope, conditions)
      if scope.respond_to?(:where)
        # Rails 3
        scope.where(conditions)
      else
        # Rails 2
        scope.scoped(:conditions => conditions)
      end
    end

    def select_scope_fields(scope, fields)
      if scope.respond_to?(:select)
        # Rails 3
        scope.select(fields)
      else
        # Rails 2
        scope.scoped(:select => fields)
      end
    end

    def drop_all_tables
      connection = ::ActiveRecord::Base.connection
      connection.tables.each do |table|
        connection.drop_table table
      end
    end

    def migrate_test_database
      print "\033[30m" # dark gray text
      drop_all_tables
      ::ActiveRecord::Migrator.migrate("#{Rails.root}/db/migrate")
      print "\033[0m"
    end

    #def scope_to_sql(scope)
    #  query = if scope.respond_to?(:to_sql)
    #    scope.to_sql
    #  else
    #    scope.construct_finder_sql({})
    #  end
    #end

    def scope_to_sql(options = {})
      if Rails.version < '3'
        scope.construct_finder_sql(options)
      else
        scope.scoped(options).to_sql
      end
    end

    def collect_column(scope, column_name, find_options = {})
      distinct = find_options.delete(:distinct)
      qualified_column_name = "`#{scope.table_name}`.`#{column_name}`"
      select = distinct ? "DISTINCT #{qualified_column_name}" : qualified_column_name
      query = if Rails.version.to_i < 3
        scope.construct_finder_sql(find_options.merge(:select => select))
      else
        scope.scoped(find_options.merge(:select => select)).to_sql
      end
      raw_values = scope.connection.select_values(query)
      column = scope.columns_hash[column_name.to_s] or raise "Could not retrieve column information: #{column_name}"
      raw_values.collect { |value| column.type_cast(value) }
    end

    #def collect_ids(scope)
    #  scope = select_scope_fields(scope, "`#{scope.table_name}`.`id`")
    #  query = scope_to_sql(scope)
    #  ::ActiveRecord::Base.connection.select_values(query).collect(&:to_i)
    #end

  end
end
