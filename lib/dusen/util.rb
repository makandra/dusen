# encoding: utf-8

module Dusen
  module Util
    extend self

    def like_expression(phrase)
      "%#{escape_for_like_query(phrase)}%"
    end

    def escape_for_like_query(phrase)
      phrase.gsub("%", "\\%").gsub("_", "\\_")
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

  end
end
