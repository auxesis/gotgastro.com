#!/usr/bin/env ruby

require 'rubygems'
Gem.path << File.expand_path(File.join(File.dirname(__FILE__), 'gems'))
require 'nokogiri'
require 'open-uri'

url = "http://www.foodauthority.nsw.gov.au/penalty-notices/default.aspx?template=results&searchname=Added%20this%20month&inthelast=60"
@exists = {}

page = open(url).read

doc = Nokogiri::HTML(page)
doc.css("table.table-data-pen tr a").each do |link|
  next if link['href'] !~ /itemId/
  exists = File.exists?(File.join(File.dirname(__FILE__), 'cache', 'penalties', link.text + '.html'))
  @exists[link.text] = exists
end

new_updates = @exists.find_all {|n| n.last == false }

if new_updates.size > 0
  puts "#{new_updates.size} unprocessed penalty notice#{new_updates.size > 1 ? "s" : ""}."
  exit 1
end
