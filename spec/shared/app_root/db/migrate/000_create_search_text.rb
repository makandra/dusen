class CreateSearchText < ActiveRecord::Migration

  def up
    create_table :search_texts, :options => 'ENGINE=MyISAM' do |t|
      t.integer :model_id
      t.string  :model_type
      t.text    :words
    end
    add_index :search_texts, [:model_type, :model_id]
    execute 'CREATE FULLTEXT INDEX fulltext_index_body ON search_texts (words)'
  end

  def down
    drop_table :search_texts
  end

end
