# encoding: utf-8

require 'dusen/version'
require 'dusen/util'
require 'dusen/token'
require 'dusen/description'
require 'dusen/parser'
require 'dusen/query'
require 'dusen/syntax'

if defined?(ActiveRecord)
  require 'dusen/active_record_ext'
  require 'dusen/search_text'
end

raise "die"

if defined?(Rails)
  puts "defined!!!"
  require 'dusen/railtie'
end
