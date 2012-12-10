class Recipe::Ingredient < ActiveRecord::Base

  self.table_name = 'recipe_ingredients'

  validates_presence_of :name

  belongs_to :recipe, :inverse_of => :ingredients

  part_of_search_text_for do
    recipe
  end

end
