class Recipe::Category < ActiveRecord::Base

  self.table_name = 'recipe_categories'

  validates_presence_of :name

  has_many :recipes

end
