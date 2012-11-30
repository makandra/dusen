# encoding: utf-8

$: << File.join(File.dirname(__FILE__), "/../../lib" )

ENV['RAILS_ENV'] = 'test'
ENV['RAILS_ROOT'] = 'app_root'

# Load the Rails environment and testing framework
require "#{File.dirname(__FILE__)}/../app_root/config/environment"
require 'rspec/rails'

# Run the migrations
Dusen::Util.migrate_test_database

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
end
