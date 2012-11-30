#namespace :dusen do
#
#  desc 'Creates a MyISAM table "search_texts" for fast Dusen searches'
#  task :create_search_text do
#    generator = File.exists?('script/generate') ? 'script/generate' : 'rails generate'
#    output = `#{generator} migration CreateSearchText`
#    output =~ %r{(db/migrate/.+?\.rb)} or raise "Could not create migration: #{output}"
#    path = $1
#    File.open(path, 'w') do |file|
#      file.write(
#"
#class CreateSearchText < ActiveRecord::Migration
#  def up
#    create_table :search_texts, :options => 'ENGINE=MyISAM' do |t|
#      t.integer :model_id
#      t.string  :model_type
#      t.text    :words
#    end
#    add_index :search_texts, [:model_type, :model_id]
#    execute 'CREATE FULLTEXT INDEX fulltext_index_body ON search_texts (words)'
#  end
#  def down
#    drop_table :search_texts
#  end
#end
#"
#    )
#    end
#  end
#
#end
