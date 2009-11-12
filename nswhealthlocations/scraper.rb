#!/usr/bin/env ruby
#

require 'rubygems'
Gem.path << File.expand_path(File.join(File.dirname(__FILE__), '..', 'gems'))
require 'nokogiri'
require 'open-uri'
require 'ym4r'
require 'optparse' 
require 'ostruct'

class Options
  def self.parse(args)
    options = OpenStruct.new
    opts = OptionParser.new do |opts|
      opts.on("-c", "--crawl", "crawl + cache nsw food authority website") do |v|
        options.crawl = v
      end
      opts.on("-e", "--extract", "extract notices from cached html") do |v|
        options.extract = v
      end
      opts.on("-g", "--geocode", "geocode extracted notices") do |v|
        options.geocode = v
      end
      opts.on("-a", "--all", "crawl, cache, extract, geocode") do |v|
        options.all = v
      end
      opts.on("-l", "--list-ungeocodable", "list notices that can't be geocoded") do |v|
        options.ungeocodable = v
      end
      opts.on("-f", "--force", "force some actions (like geocoding)") do |v|
        options.force = v
      end
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
     end
    end
    opts.parse!

    options.base_url = "http://www2.health.nsw.gov.au/services/Default.cfm?S_UNITNAME=&S_SERVICENAME=8&S_DESCRIPTION=&S_AHSLONG=&S_PCODE=&CFID=803193&CFTOKEN=fff25a983ec6dc5d-E69DF5FA-1185-51F1-29017C71B50278C6"
    return options
  end
end

def serialise(notices, opts = {})
  opts[:base] ||= 'extracted'
  notices.each do |notice|
    puts "Serialising #{notice[:id]}"
    filename = File.join(File.dirname(__FILE__), opts[:base], opts[:type].to_s, "#{notice[:id]}.yaml")
    File.open(filename, 'w') do |f|
      f << YAML::dump(notice)
    end
  end
end

def read_yaml(opts={})
  opts[:type] ||= :prosecutions
  opts[:base] ||= 'extracted'
  Dir.glob(File.join(File.dirname(__FILE__), opts[:base], opts[:type].to_s, '*.yaml')).map do|file| 
    YAML::load(File.read(file))
  end
end

class Crawler

  attr_accessor :url, :type

  def initialize(opts)
    unless opts[:base_url] 
      raise ArgumentError, "you need to specify :base_url"
    end
    @base_url  = opts[:base_url]
    @filenames = []
  end

  # main entry point
  def crawl!
    puts "Getting list of current notices"
  
    notices = get_index()
    
    notices.each do |notice|
      puts "Caching #{notice[:id]}"
      filename = File.join(File.dirname(__FILE__), 'cache', @type.to_s, "#{notice[:id]}.html")
      html = get_page(notice[:url])
      serialise(html, filename)
      @filenames << filename
    end
  
    return @filenames 
  end

  def serialise(html, filename)
    File.open(filename, 'w') do |f|
      f << html
    end
    return true
  end

  def get_page(url)
    begin 
      html = open(url).read
    rescue OpenURI::HTTPError => exception
      exception.message
    end
    return html
  end

  def get_index
    puts "Getting index of services"
    page = get_page(@base_url)
    doc = Nokogiri::HTML(page)

    pagination = doc.search("tr.Footer td").last.text
    scrubbed = pagination.gsub(/(([\000-\011\013-\014\016-\037\177-\400])+\s?)/, '')
    max_pages = scrubbed.match(/of(\d+)/).captures
    if max_pages.size > 1 || max_pages == nil
      raise "pagination regex didn't work - page layout probably changed"
    else
      max_pages = max_pages.first.to_i
    end
    
    @pages = []
    (1..max_pages).each do |page_number|
      url = "http://www2.health.nsw.gov.au/services/Default.cfm?S_UNITNAME=&S_SERVICENAME=8&S_DESCRIPTION=&S_AHSLONG=&S_PCODE=&CFID=803256&CFTOKEN=467eb016ea54a9f7-E6C83597-1185-51F1-296808B2CAC3D917&AHS_SECTOR_SERVICE_SERVIC3Page=#{page_number}"
      @pages << get_page(url)
    end

    p @pages


   
    index = get_services(doc)

    return index
  end

  def filter_penalties(doc)
    penalties = []
    doc.css("table#table.table-data-pen.sortable tbody tr a").each do |row|
      # there are now extra <a>s in the markup. we have to filter them
      next if row['href'] !~ /itemId/
      # construct url from url + page href
      penalties << { :id => row.text, :url => @base_url + row['href'] }
    end
    return penalties
  end

  def filter_prosecutions(doc)
    prosecutions = []
    doc.css("table#table.table-data-pros.sortable tbody tr a").each do |row|
      next unless row['href'] =~ /^\/aboutus\/offences\/prosecutions/
      page = row['href'].split('/').last
      # construct url from base and chopped page href
      prosecutions << { :id => row['href'].split('/').last.gsub(/offences-details-/, ''), :url => url + page }
    end

    return prosecutions
  end

end

if __FILE__ == $0 then

  @options = Options.parse(ARGV)

  case 
  when @options.crawl
    c = Crawler.new(:base_url => @options.base_url)
    c.crawl!
  else
    puts "Usage: #{$0} --help"
    exit 1
  end
  
end


