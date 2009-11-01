
require 'rubygems'
require 'rake'
require 'spec/rake/spectask'
require 'fileutils'

task 'default' => ['spec']

desc 'run specs against crawler'
task 'spec' do
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['specs/*_spec.rb']
    t.warning = false
  end
end

desc "crawl, extract, geocode penalties"
task :shebang do 
  ruby "scraper.rb --crawl --penalties"
  ruby "scraper.rb --extract --penalties"
  ruby "scraper.rb --geocode --penalties"
end
