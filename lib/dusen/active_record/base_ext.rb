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
              @search_syntax.search(self, query_string)
            end
          end
          @search_syntax
        end

        def search_text?
          !!@has_search_text
        end

        def index_search_texts
          Dusen::ActiveRecord::SearchText.synchronize_model(self)
        end

        def search_text(&text)

          @has_search_text = true

          has_one :search_text_record, :as => :source, :dependent => :destroy, :class_name => '::Dusen::ActiveRecord::SearchText', :inverse_of => :source

          after_create :create_initial_search_text_record

          after_update :invalidate_search_text

          define_method :search_text do
            new_text = instance_eval(&text)
            new_text = Array.wrap(new_text).flatten.collect(&:to_s).join(' ').gsub(/\s+/, ' ').strip
            new_text
          end

          define_method :index_search_text do
            ensure_search_text_record_built
            search_text_record.update_words!(search_text)
            true
          end

          define_method :invalidate_search_text do
            ensure_search_text_record_built
            search_text_record.invalidate!
            true
          end

          private

          define_method :create_initial_search_text_record do
            ensure_search_text_record_built(:stale => true)
            search_text_record.save!
          end

          define_method :ensure_search_text_record_built do |*args|
            attributes = args.first || {}
            search_text_record.present? or build_search_text_record(attributes)
          end

          search_syntax do
            search_by :text do |scope, phrases|
              Dusen::ActiveRecord::SearchText.match(scope, phrases)
            end
          end

        end

        def part_of_search_text_for(&associations)
          invalidate_associations_method = "invalidate_search_text_for_associated_records"

          before_save invalidate_associations_method
          before_destroy invalidate_associations_method

          private

          define_method invalidate_associations_method do
            associated_records = Array.wrap(instance_eval(&associations)).flatten
            associated_records.each(&:invalidate_search_text)
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

