# encoding: utf-8

require 'dusen/version'
require 'dusen/util'
require 'dusen/token'
require 'dusen/description'
require 'dusen/parser'
require 'dusen/query'
require 'dusen/syntax'

if defined?(ActiveRecord)
  require 'edge_rider'
  require 'dusen/active_record/base_ext'
  require 'dusen/active_record/search_text'
end

#if defined?(Rails::Railstie)
#  require 'dusen/railtie'
#end
