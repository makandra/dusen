class CreateRecipeModels < ActiveRecord::Migration

  def self.up
    create_table :recipes do |t|
      t.string :name
      t.integer :category_id
    end
    create_table :recipe_ingredients do |t|
      t.string :name
      t.integer :recipe_id
    end
    create_table :recipe_categories do |t|
      t.string :name
    end
  end

  def self.down
    drop_table :recipes
    drop_table :recipe_ingredients
    drop_table :recipe_categories
  end

end
