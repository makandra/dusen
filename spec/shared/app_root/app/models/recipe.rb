class Recipe < ActiveRecord::Base

  validates_presence_of :name

  has_many :ingredients, :class_name => 'Recipe::Ingredient'
  belongs_to :category, :class_name => 'Recipe::Category'

  search_syntax

  search_text do
    [name, category.name, ingredients.collect(&:name)]
  end

end
