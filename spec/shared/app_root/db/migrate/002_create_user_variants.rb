# encoding: utf-8

class CreateUserVariants < ActiveRecord::Migration

  def self.user_tables
    [:users_with_fulltext, :users_without_fulltext]
  end

  def self.up
    user_tables.each do |user_table|
      create_table user_table do |t|
        t.string :name
        t.string :email
        t.string :city
      end
    end
  end

  def self.down
    user_tables.each do |user_table|
      drop_table user_table
    end
  end

end
