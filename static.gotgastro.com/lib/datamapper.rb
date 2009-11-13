require 'rubygems'
Gem.path << File.expand_path(File.join(File.dirname(__FILE__), '..', 'gems'))

require 'dm-core'

DataMapper.setup(:default, "sqlite3://#{File.expand_path(File.join(File.dirname(__FILE__), '..', 'gastro.db'))}")

require 'lib/models/notice'
require 'lib/models/penalty'
require 'lib/models/prosecution'
require 'lib/models/postcode'

