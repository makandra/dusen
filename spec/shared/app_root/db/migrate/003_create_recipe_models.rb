class CreateRecipeModels < ActiveRecord::Migration

  def self.up
    create_table :recipes do |t|
      t.string :name
    end
    create_table :recipe_ingredients do |t|
      t.string :name
    end
    create_table :recipe_category do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :recipes
    drop_table :recipe_ingredients
    drop_table :recipe_categories
  end

end
