class Recipe < ActiveRecord::Base

  validates_presence_of :name

  has_many :ingredients, :class_name => 'Recipe::Ingredient', :inverse_of => :recipe
  belongs_to :category, :class_name => 'Recipe::Category', :inverse_of => :recipes

  search_text do
    [name, category.andand.name, ingredients.collect(&:name)]
  end

  search_syntax do

    search_by :category do |scope, category_name|
      scope.joins(:category).where('recipe_categories.name = ?', category_name)
    end

  end

end
