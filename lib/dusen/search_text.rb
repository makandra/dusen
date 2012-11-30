module Dusen
  class SearchText < ActiveRecord::Base

    self.table_name = 'search_texts'

    belongs_to :model, :polymorphic => true

    def self.rewrite(model, words)
      erase(model)
      create!(:model => model, :words => words)
    end

    private

    def self.erase(model)
      existing = Util.append_scope_conditions(model.class, :model_type => model.type, :model_id => model.id)
      existing.delete_all
    end

  end
end
