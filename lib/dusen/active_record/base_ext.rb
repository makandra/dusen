# encoding: utf-8

module Dusen
  module ActiveRecord
    module BaseExt
      module ClassMethods

        def search_syntax(&dsl)
          if dsl
            @search_syntax = Dusen::Description.read_syntax(&dsl)
            singleton_class.send(:define_method, :search) do |query_string|
              @search_syntax.search(self, query_string)
            end
          else
            @search_syntax
          end
        end

        def search_text(&text)

          after_save :index_search_text

          define_method :index_search_text do
            new_text = instance_eval(&text)
            new_text = Array.wrap(new_text).collect(&:to_s).join(' ').gsub(/\s+/, ' ').strip
            Dusen::ActiveRecord::SearchText.rewrite(self, new_text)
            true
          end

        end

        def where_like(conditions)
          scope = self
          conditions.each do |field_or_fields, query|
            fields = Array(field_or_fields).collect do |field|
              Util.qualify_column_name(scope, field)
            end
            Array.wrap(query).each do |phrase|
              phrase_with_placeholders = fields.collect { |field| "#{field} LIKE ?" }.join(' OR ')
              like_expression = Dusen::Util.like_expression(phrase)
              bindings = [like_expression] * fields.size
              conditions = [ phrase_with_placeholders, *bindings ]
              scope = Util.append_scope_conditions(scope, conditions)
            end
          end
          scope
        end

      end
    end
  end
end

ActiveRecord::Base.send(:extend, Dusen::ActiveRecord::BaseExt::ClassMethods)

