module Dusen
  module ActiveRecord
    class SearchText < ::ActiveRecord::Base

      self.table_name = 'search_texts'

      belongs_to :source, :polymorphic => true

      def self.rewrite(source, words)
        erase(source)
        create!(:source => source, :words => words)
      end

      def self.for_model(model)
        Util.append_scope_conditions(scoped({}), :source_type => model.name)
      end

      def self.match(model, words)
        Dusen::Util.append_scope_conditions(
          model,
          :id => matching_source_ids(model, words)
        )
      end

      def self.matching_source_ids(model, words)
        conditions = [
          'MATCH (words) AGAINST (? IN BOOLEAN MODE)',
          Dusen::Util.boolean_fulltext_query(words)
        ]
        matching_texts = Dusen::Util.append_scope_conditions(for_model(model), conditions)
        Dusen::Util.collect_column(matching_texts, :source_id)
      end

      private

      def self.erase(source)
        existing = for_model(source.class)
        existing = Util.append_scope_conditions(existing, :source_id => source.id)
        existing.delete_all
      end

    end
  end
end
