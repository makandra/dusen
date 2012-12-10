class Recipe::Category < ActiveRecord::Base

  self.table_name = 'recipe_categories'

  validates_presence_of :name

  has_many :recipes, :inverse_of => :category

  part_of_search_text_for do
    recipes
  end

end
