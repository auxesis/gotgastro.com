
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

desc "freeze deps"
task :deps do

  deps = {'nokogiri' => "= 1.2.2",
          'dm-core' => ">= 0.9.11",
          'ym4r' => ">= 0.6.1"}

  puts "\ninstalling dependencies. this will take a few minutes."

  deps.each_pair do |dep, version|
    next if Dir.glob("gems/gems/#{dep}-#{version.split.last}").size > 0
    puts "\ninstalling #{dep} (#{version})"
    system("gem install #{dep} --version '#{version}' -i gems --no-rdoc --no-ri")
  end

end

desc "crawl, extract, geocode penalties"
task :shebang do 
  ruby "scraper.rb --crawl --penalties"
  ruby "scraper.rb --extract --penalties"
  ruby "scraper.rb --geocode --penalties"
end
