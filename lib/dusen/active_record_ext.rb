module Dusen
  module ActiveRecord

    def search_syntax(&dsl)
      @dusen_syntax = Dusen::Description.read_syntax(&dsl)
      singleton_class.send(:define_method, :search) do |query_string|
        @dusen_syntax.search(self, query_string)
      end
    end

    def where_like(conditions)
      scope = self
      conditions.each do |field_or_fields, query|
        fields = Array(field_or_fields).collect do |field|
          Util.qualify_column_name(scope, field)
        end
        query_with_placeholders = fields.collect { |field| "#{field} LIKE ?" }.join(' OR ')
        like_expression = Dusen::Util.like_expression(query)
        bindings = [like_expression] * fields.size
        conditions = [ query_with_placeholders, *bindings ]
        scope = Util.append_scope_conditions(scope, conditions)
      end
      scope
    end

  end
end

ActiveRecord::Base.send(:extend, Dusen::ActiveRecord)
