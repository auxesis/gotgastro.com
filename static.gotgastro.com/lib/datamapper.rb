#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'extlib'
require 'data_mapper'
require 'pathname'
$: << (Pathname.new(__FILE__).parent.parent + 'lib').expand_path
require 'gastro/penalty'

database_path = (Pathname.new(__FILE__).parent.parent + 'data' + 'nswfa-penalty_notices.sqlite').expand_path
DataMapper.setup(:default, "sqlite:///#{database_path}")

