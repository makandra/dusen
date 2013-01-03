require 'set'

module Dusen
  module ActiveRecord
    class SearchText < ::ActiveRecord::Base

      self.table_name = 'search_texts'

      belongs_to :source, :polymorphic => true, :inverse_of => :search_text_record

      def update_words!(words)
        update_attributes!(:words => words, :stale => false)
      end

      def invalidate!
        update_attributes!(:stale => true)
      end

      def self.for_model(model)
        Util.append_scope_conditions(scoped({}), :source_type => model.name)
      end

      def self.invalid
        scoped(:conditions => { :stale => true })
      end

      def self.synchronize_model(model)
        invalid_index_records = for_model(model).invalid
        source_ids = Util.collect_column(invalid_index_records, :source_id)
        pending_source_ids = Set.new(source_ids)
        source_records = Util.append_scope_conditions(model, :id => source_ids).to_a
        source_records.each do |source_record|
          source_record.index_search_text
          pending_source_ids.delete(source_record.id)
        end
        if pending_source_ids.present?
          invalid_index_records.delete_all(:source_id => pending_source_ids.to_a)
        end
        true
      end

      def self.match(model, words)
        synchronize_model(model) if model.search_text?
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

    end
  end
end
