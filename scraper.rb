#!/usr/bin/env ruby
#

require 'rubygems'
Gem.path << File.expand_path(File.join(File.dirname(__FILE__), 'gems'))
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
      opts.on("-p", "--prosecutions", "work with prosecutions") do |v|
        options.prosecutions = v
      end
      opts.on("-n", "--penalties", "work with penalties") do |v|
        options.penalties = v
      end
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
     end
    end
    opts.parse!

    unless options.prosecutions || options.penalties then
      puts "You need to specify either --penalties or --prosecutions!\n\n"
      puts opts
      exit 1
    end

    options.data_type = options.prosecutions ? :prosecutions : :penalties
    if options.data_type == :penalties 
      #options.url = "http://www.foodauthority.nsw.gov.au/penalty-notices/"
      options.url = "http://www.foodauthority.nsw.gov.au/penalty-notices/default.aspx?template=results"
      options.base_url = "http://www.foodauthority.nsw.gov.au/penalty-notices/default.aspx"
    else
      options.url = "http://www.foodauthority.nsw.gov.au/aboutus/offences/prosecutions/"
    end

    return options
  end
end

class Extractor


  def initialize(opts)
    unless opts[:files] && opts[:type]
      raise ArgumentError "you need to specify :files & :type"
    end
    @files = opts[:files]
    @type = opts[:type]
  end

  def extract_penalties(filename)
    doc = Nokogiri::HTML(File.read(filename))

    notice = {}
    fields = { 0 => :id, 1 => :trading_name, 2 => :address, 3 => :council_area, 4 => :offence_date, 
               5 => :offence_code, 6 => :offence_description, 7 => :penalty_amount, 
               8 => :served_to, 9 => :action_date, 10 => :pursued_by, 11 => :notes }
    
    doc.css("table.table-data-pros tr").each_with_index do |row, index|
      notice[fields[index]] = row.css('td')[1].text.strip
    end

    notice[:url] = "http://www.foodauthority.nsw.gov.au/penalty-notices/?template=detail&data=data&itemId=#{notice[:id]}"
  
    return notice
  end
  
  def extract_prosecution(filename)
    doc = Nokogiri::HTML(File.read(filename))
  
    notice = {}
    fields = { 0 => :trading_name, 4 => :address, 3 => :council_area, 5 => :offence_date, 
               6 => :offence_description, 10 => :penalty_amount, 1 => :served_to,
               2 => :business_address,
               8 => :prosecution_decision, 7 => :action_date, 13 => :notes, 9 => :court,
               12 => :pursued_by, 11 => :prosecution_decision_description}
    
    notice[:id] = File.basename(File.basename(filename), '.html')
    
    doc.css("table.table-data-pros tr").each_with_index do |row, index|
      # sanitise input with nasty regex.
      # strip all non-'keyboard' characters, bar \n + \r. numbers are in octal.
      #
      # pretty sure these docs are transcribed directly from ms word, so they 
      # have all sorts of fucked up control sequences for bullet points 
      # that need to be stripped (e.g. \342\200\223)
      #
      # character reference at http://tinyurl.com/5qses3
      notice[fields[index]] = row.css('td')[1].text.strip.gsub(/(([\000-\011\013-\014\016-\037\177-\400])+\s?)/, '')
    end

    notice[:address] = notice[:address].gsub(/[\n|\r]*/, '').split.join(' ')
    notice[:offence_description] = notice[:offence_description].split("\r\n").map {|line| line.strip }

    # extract monetary amounts from penalties
    #notice[:penalty_amount] =~ /[t|T]otal/
    #notice[:penalty_amount] = notice[:penalty_amount].scan(/(\$(?:\d+,?)*(?:\d+\.?\d+))/).flatten.map { |amount| amount.gsub(/[$|,]/, '').to_f } # fuck me

    notice[:url] = %[http://www.foodauthority.nsw.gov.au/aboutus/offences/prosecutions/offences-details-] + notice[:id]
    notice[:notes] = nil if notice[:notes].size == 2
    notice[:action_date] = notice[:action_date].gsub(/^.*(\d{4,4}-\d{2,2}-\d{2,2}).*$/, '\1')
    notice.delete(:business_address)

    return notice
  end
  
  
  def extract!
    @notices = []
    @files.each do |filename|
      puts "Extracting meaningful data from #{filename}"
      case @type
      when :prosecutions
        notice = extract_prosecution(filename)
      when :penalties
        notice = extract_penalties(filename)
      end
      @notices << notice
    end
  
    return @notices
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
    unless opts[:url] && opts[:type]
      raise ArgumentError "you need to specify :url & :type"
    end
    @url  = opts[:url]
    @type = opts[:type]
    @base_url  = opts[:base_url]
    @filenames = []
  end

  # main entry point
  def crawl!
    puts "Getting list of current notices"
  
    notices = get_index()
    # http://www.foodauthority.nsw.gov.au/penalty-notices/
    # http://www.foodauthority.nsw.gov.au/aboutus/offences/prosecutions/
    
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
    puts "Getting latest #{@type.to_s}."
    page = get_page(@url)
    doc = Nokogiri::HTML(page)
    
    case @type
    when :penalties
      index = filter_penalties(doc)
    when :prosecutions
      index = filter_prosecutions(doc)
    end

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

class Geocoder

  attr_accessor :notices, :force

  def initialize(opts)
    unless opts[:notices]
      raise ArgumentError "you need to specify :notices"
    end
    @notices = opts[:notices]
    @force ||= opts[:force]
  end

  def geocode!
    @notices.map do |notice|
      if notice[:latitude] && !@options.force
        puts "has previously been geocoded! use --force to re-geocode."
        next
      end
 
      tries = 3
      begin 
        location = Ym4r::GoogleMaps::Geocoding.get(notice[:address]).first
      rescue OpenURI::HTTPError
        retry if (tries =- 1) > 0
      end

      if location
        puts "Successfully geocoded #{notice[:id]}"
        notice[:latitude] = location.latitude
        notice[:longitude] = location.longitude
      else
        puts "Couldn't geocode #{notice[:id]}"
      end
      notice
    end
  
    return notices
  end

end

if __FILE__ == $0 then

  @options = Options.parse(ARGV)

  case 
  when @options.crawl
    c = Crawler.new(:url => @options.url, :type => @options.data_type, :base_url => @options.base_url)
    c.crawl!

  when @options.extract
    html = Dir.glob(File.join(File.dirname(__FILE__), 'cache', @options.data_type.to_s, '*.html'))
    e = Extractor.new(:files => html, :type => @options.data_type)
    notices = e.extract!
    serialise(notices, :type => @options.data_type)

  when @options.geocode 
    notices = read_yaml(:type => @options.data_type)
    g = Geocoder.new(:notices => notices)
    geocoded_notices = g.geocode!
    serialise(geocoded_notices, :base => 'geocoded', :type => @options.data_type)

  when @options.all
    c = Crawler.new(:url => @options.url, :type => @options.data_type, :base_url => @options.base_url)
    c.crawl!
    
    e = Extractor.new(:files => html, :type => @options.data_type)
    notices = e.extract!
    serialise(notices, :type => @options.data_type)
    
    g = Geocoder.new(:notices => notices)
    geocoded_notices = g.geocode!
    serialise(geocoded_notices)
    
  when @options.ungeocodable
    notices = read_yaml(:type => @options.data_type)
    notices = notices.reject { |n| n[:latitude] }
    puts notices.to_yaml

  else
    puts "Usage: #{$0} --help"
    exit 1
  end
  
end


