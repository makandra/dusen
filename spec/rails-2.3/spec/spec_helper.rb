# encoding: utf-8

$: << File.join(File.dirname(__FILE__), "/../../lib" )

ENV['RAILS_ENV'] = 'test'

# Load the Rails environment and testing framework
require "#{File.dirname(__FILE__)}/../app_root/config/environment"
require 'spec/rails'

# Requires supporting files with custom matchers and macros, etc in ./support/ and its subdirectories.
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

# Run the migrations
Dusen::Util.migrate_test_database

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
end
