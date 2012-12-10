# encoding: utf-8

module Dusen
  module ActiveRecord
    module BaseExt
      module ClassMethods

        def search_syntax(&dsl)
          @search_syntax ||= Dusen::Syntax.new
          Dusen::Description.parse_syntax(@search_syntax, &dsl) if dsl
          unless singleton_class.method_defined?(:search)
            singleton_class.send(:define_method, :search) do |query_string|
              Dusen::ActiveRecord::SearchText.rewrite_all_invalid(self) if search_text?
              @search_syntax.search(self, query_string)
            end
          end
          @search_syntax
        end

        def search_text?
          !!@has_search_text
        end

        def search_text(&text)

          @has_search_text = true

          has_one :search_text, :as => :source, :dependent => :destroy, :class_name => '::Dusen::ActiveRecord::SearchText'

          after_create :index_search_text

          after_update :invalidate_search_text

          define_method :index_search_text do
            new_text = instance_eval(&text)
            new_text = Array.wrap(new_text).flatten.collect(&:to_s).join(' ').gsub(/\s+/, ' ').strip
            Dusen::ActiveRecord::SearchText.rewrite(self, new_text)
            true
          end

          define_method :invalidate_search_text do
            unless @search_text_invalidated
              Dusen::ActiveRecord::SearchText.invalidate(self)
            end
            @search_text_invalidated = false
            true
          end

          search_syntax do
            search_by :text do |scope, phrases|
              Dusen::ActiveRecord::SearchText.match(scope, phrases)
            end
          end

        end

        def part_of_search_text_for(&associations)
          invalidate_associations_method = "invalidate_search_text_for_associated_records"
          remember_associations_method = "remember_associated_records_with_search_text"
          associations_method = "associated_records_with_search_text"

          before_validation remember_associations_method
          before_destroy remember_associations_method

          after_save invalidate_associations_method
          after_destroy invalidate_associations_method

          private

          define_method invalidate_associations_method do
            records = @associated_records_with_search_text | send(associations_method)
            p records
            records.each(&:invalidate_search_text)
            @associated_records_with_search_text = nil
            true
          end

          define_method remember_associations_method do
            @associated_records_with_search_text = send(associations_method)
            true
          end

          define_method associations_method do
            Array.wrap(instance_eval(&associations)).flatten
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

