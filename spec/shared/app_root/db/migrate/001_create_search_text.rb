class CreateSearchText < ActiveRecord::Migration

  def self.up
    create_table :search_texts, :options => 'ENGINE=MyISAM' do |t|
      t.integer :source_id
      t.string  :source_type
      t.text    :words
    end
    add_index :search_texts, [:source_type, :source_id]
    execute 'CREATE FULLTEXT INDEX fulltext_index_words ON search_texts (words)'
  end

  def self.down
    drop_table :search_texts
  end

end
