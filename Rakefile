#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'rake'
require 'fileutils'

task 'default' => ['spec']

desc 'run specs against crawler'
task 'spec' do
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['specs/*_spec.rb']
    t.warning = false
  end
end

desc "Fetch the latest penalty notices from scraperwiki.com"
task :fetch do
  source      = "https://scraperwiki.com/scrapers/export_sqlite/nsw_food_authority_-_register_of_penalty_notices/"
  destination = File.join(File.dirname(__FILE__), "data/nswfa-penalty_notices.sqlite")
  system("wget --no-check-certificate -c #{source} -O #{destination}")
end

desc "Geocode the latest penalty notices"
task :geocode do
  ruby "bin/geocode"
end
