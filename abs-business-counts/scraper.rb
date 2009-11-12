#!/usr/bin/env ruby
#

require 'rubygems'
Gem.path << File.expand_path(File.join(File.dirname(__FILE__), '..', 'gems'))
require 'nokogiri'
require 'open-uri'
require 'ym4r'
require 'optparse' 
require 'ostruct'
require 'tmpdir'
require 'zip/zip'
require 'fileutils'
require 'fastercsv'
require 'yajl'
require 'yajl/json_gem'


class Options
  def self.parse(args)
    options = OpenStruct.new
    opts = OptionParser.new do |opts|
      opts.on('--output-dir DIRECTORY', "Where data should be serialised") do |directory|
        options.output_directory = directory
      end
      opts.on('--download', "Download the 8165009 data") do 
        options.download = true
      end
      opts.on('--unzip', "Extract the 8165009 data from a previously downloaded zip") do 
        options.unzip = true
      end
      opts.on('--convert', "Convert the 8165009 data from XLS to CSV") do 
        options.convert = true
      end
      opts.on('--transform', "Convert the 8165009 data from CSV to JSON") do 
        options.transform = true
      end
      opts.on('--normalise', "Normalise the 8165009 JSON data") do 
        options.normalise = true
      end
      opts.on('--geocode', "Geocode the 8165009 JSON data") do 
        options.geocode = true
      end
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
     end
    end
    opts.parse!

    options.data_url = "http://www.abs.gov.au/AUSSTATS/subscriber.nsf/log?openagent&8165009.zip&8165.0&Data%20Cubes&E530CAB1491CE443CA2573B70011AD1A&0&Jun%202003%20to%20Jun%202007&21.12.2007&Latest"

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

if __FILE__ == $0 then

  @options = Options.parse(ARGV)

  output_directory = @options.output_directory ? FileUtils.mkdir_p(@options.output_directory) : Dir.mktmpdir
  zip_filename  = File.join(output_directory, "abs-8165009.zip")
  xls_filename  = File.join(output_directory, "abs-8165009.xls")
  csv_filename  = File.join(output_directory, "abs-8165009.csv")
  json_filename = File.join(output_directory, "abs-8165009.json")
  normalised_json_filename = File.join(output_directory, "abs-8165009-normalised.json")
  geocoded_json_filename = File.join(output_directory, "abs-8165009-normalised.json")

  if @options.download
    puts 'Downloading ZIP...'
    # this is in no way memory efficient - need to refactor
    
    zipfile = open(@options.data_url).read
    File.open(zip_filename, 'w') do |f|
      f << zipfile
    end
  end

  if @options.unzip
    puts 'Extracting XLS from ZIP...'
    Zip::ZipFile.open(zip_filename) do |zipfile|
      xls = zipfile.find_entry("8165009.xls")
      xls.extract(xls_filename) { true }
    end
  end

  if @options.convert
    puts 'Converting XLS to CSV...'
    raise "You need to have Gnumeric installed" unless system("which ssconvert")
    command = "ssconvert --import-type=Gnumeric_Excel:excel --export-type=Gnumeric_stf:stf_csv #{xls_filename} #{csv_filename}"
    system(command)
  end

  if @options.transform
    puts 'Transforming CSV (from XLS) to JSON'
    csv = FasterCSV.read(csv_filename)

    # headers start at line 6
    headers = csv[5]
    # work out where data lives on each line
    indexes = {}
    indexes['industry']        = headers.index(headers.grep(/^\s*industry\s*$/i).first)
    indexes['suburb']          = headers.index(headers.grep(/^\s*sla\s*labels\s*$/i).first)
    indexes['total_businesses'] = headers.index(headers.grep(/^\s*total\s*$/i).first)

    @areas = []

    # data starts at line 9
    csv[8..-1].each do |row|
      if row[indexes['industry']] =~ /ACCOMMODATION CAFES AND RESTAURANTS/i
        area = {'suburb' => row[indexes['suburb']], 'total_businesses' => row[indexes['total_businesses']]}
        @areas << area
      end
    end

    File.open(json_filename, 'w') do |f|
      f << @areas.to_json
    end

  end

  if @options.normalise
    json = File.new(json_filename, 'r')
    parser = Yajl::Parser.new
    @areas = parser.parse(json)
    
    @areas.each do |area|
      area['suburb'].gsub!(/\s*\(.+$/, '')
      area['suburb'].gsub!(/\s*- SSD Bal$/, '')
    end

    # aggregate the areas together
    @normalised_areas = []
    unique_areas = @areas.map { |area| area['suburb'] }.uniq
    unique_areas.each do |area|
      sum = 0
      @areas.find_all { |a| a['suburb'] == area }.each do |entry|
        sum += entry['total_businesses'].to_i
      end
      @normalised_areas << {'suburb' => "#{area}, Australia", 'total_businesses' => sum}
    end
    
    File.open(normalised_json_filename, 'w') do |f|
      f << @normalised_areas.to_json
    end
  end

  if @options.geocode
    json = File.new(normalised_json_filename, 'r')
    parser = Yajl::Parser.new
    @areas = parser.parse(json)

    @areas.each_with_index do |area, index|

      #break if index > 5

      # As of 11/2009, the geocoder service sometimes throws 403s. 
      # Retrying the request appears to work.
      tries = 3
      begin 
        location = Ym4r::GoogleMaps::Geocoding.get(area['suburb']).first
      rescue OpenURI::HTTPError
        puts "Request failed, trying again..."
        retry if (tries =- 1) > 0
      end

      if location 
        puts "Successfully geocoded #{area['suburb']}"
        p location
        area['lat'] = location.latitude
        area['lng'] = location.longitude
      else
        puts "Couldn't geocode #{area['suburb']}"
      end
    end

    File.open(geocoded_json_filename, 'w') do |f|
      f << @areas.to_json
    end
  end


end


