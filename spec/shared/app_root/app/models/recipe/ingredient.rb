class Recipe::Ingredient < ActiveRecord::Base

  self.table_name = 'recipe_ingredients'

  validates_presence_of :name

  belongs_to :recipe

end
