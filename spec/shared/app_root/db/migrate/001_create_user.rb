# encoding: utf-8

class CreateUser < ActiveRecord::Migration

  def self.up
    create_table :users do |t|
      t.string :name
      t.string :email
      t.string :city
    end
  end

  def self.down
    drop_table :users
  end

end
