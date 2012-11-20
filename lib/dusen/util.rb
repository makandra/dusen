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

  end
end