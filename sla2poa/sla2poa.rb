#!/usr/bin/env ruby
#
# 2009 11 12 
# Lindsay Holmwood <lindsay@holmwood.id.au>
#
# sla2poa.rb
#
# Description
# -----------
#
# Downloads, unzips, and transforms the Australian Bureau of Statistics (ABS)
# Statistical Local Area (SLA) <=> Postal Areas (POA) mappings. 
#
# Background
# -----------
#
# In 2006 the ABS switched to representing geographing data within their 
# publications from plain postcodes to SLAs, so data could be easily aggregated
# across larger geographical areas[0]. 
#
# They provide mapping tables from SLAs <=> POAs for people requiring postcode 
# information. 
#
# This tool downloads the mapping tables from the ABS and transforms it into 
# JSON, so it can easily be consumed over the web, or by other programming 
# languages.
#
# Detailed ABS product information available at: 
# http://www.abs.gov.au/AUSSTATS/abs@.nsf/39433889d406eeb9ca2570610019e9a5/caf984c0e9e6f3f3ca25730c00008632!OpenDocument
# 
# [0] Point 62: http://www.abs.gov.au/AUSSTATS/abs@.nsf/Lookup/8165.0Explanatory%20Notes1Jun%202003%20to%20Jun%202007?OpenDocument

require 'rubygems'
Gem.path << File.expand_path(File.join(File.dirname(__FILE__), '..', 'gems'))
require 'nokogiri'
require 'open-uri'
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
      opts.on('--download', "Download the ABS Postal Area Concordances data") do 
        options.download = true
      end
      opts.on('--unzip', "Extract the ABS Postal Area Concordances data from a previously downloaded zip") do 
        options.unzip = true
      end
      opts.on('--transform', "Convert the ABS Postal Area Concordances data from CSV to JSON") do 
        options.transform = true
      end
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
     end
    end
    opts.parse!

    options.data_url = "http://www.abs.gov.au/AUSSTATS/subscriber.nsf/log?openagent&2905055001%20poa%202006%20from%20sla%202006.zip&2905.0.55.001&Data%20Cubes&9C820F5FA88F9CAACA257309001F88AA&0&Aug%202006&02.07.2007&Latest"

    return options
  end
end

if __FILE__ == $0 then

  @options = Options.parse(ARGV)

  output_directory = @options.output_directory ? FileUtils.mkdir_p(@options.output_directory) : Dir.mktmpdir
  zip_filename  = File.join(output_directory, "abs-2905.0.55.001.zip")
  csv_filename  = File.join(output_directory, "abs-2905.0.55.001.csv")
  json_filename = File.join(output_directory, "abs-2905.0.55.001.json")

  if @options.download
    puts 'Downloading ZIP...'
    # this is in no way memory efficient - need to refactor
    
    zipfile = open(@options.data_url).read
    File.open(zip_filename, 'w') do |f|
      f << zipfile
    end
  end

  if @options.unzip
    puts 'Extracting CSV from ZIP...'
    Zip::ZipFile.open(zip_filename) do |zipfile|
      csv = zipfile.find_entry("CP2006POA_2006SLA.TXT")
      csv.extract(csv_filename) { true }
    end
  end

  if @options.transform
    puts 'Transforming CSV to JSON'
    csv = FasterCSV.read(csv_filename)

    # headers start at line 1
    headers = csv[0]
    # work out where data lives on each line
    indexes = {}
    indexes['poa_code'] = 0
    indexes['sla_code'] = 2
    indexes['sla_name'] = 3

    @mappings = []

    # data starts at line 2
    csv[1..-1].each do |row|
      area = { 'poa_code' => row[indexes['poa_code']], 
               'sla_code' => row[indexes['sla_code']],
               'sla_name' => row[indexes['sla_name']] }
      @mappings << area
    end

    File.open(json_filename, 'w') do |f|
      f << @mappings.to_json
    end

  end

end


