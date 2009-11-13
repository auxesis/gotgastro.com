#!/usr/bin/env ruby
#
# 2009 11 12 
# Lindsay Holmwood <lindsay@holmwood.id.au>
#
# auspost-suburbs
#
# Description
# -----------
#
# Downloads, unzips, and transforms the Australia Post Postcode & Suburb database.
#

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
      opts.on('--download', "Download the Auspost Postcode data") do 
        options.download = true
      end
      opts.on('--unzip', "Extract the Auspost Postcode data from a previously downloaded zip") do 
        options.unzip = true
      end
      opts.on('--transform', "Convert the Auspost Postcode data from CSV to JSON") do 
        options.transform = true
      end
      opts.on_tail("-h", "--help", "Show this message") do
        puts opts
        exit
     end
    end
    opts.parse!

    options.data_url = "http://www1.auspost.com.au/download/pc-book.zip"

    return options
  end
end

if __FILE__ == $0 then

  @options = Options.parse(ARGV)

  output_directory = @options.output_directory ? FileUtils.mkdir_p(@options.output_directory) : Dir.mktmpdir
  zip_filename  = File.join(output_directory, "auspost-postcodes-and-suburbs.zip")
  csv_filename  = File.join(output_directory, "auspost-postcodes-and-suburbs.csv")
  json_filename = File.join(output_directory, "auspost-postcodes-and-suburbs.json")

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
      zipfile.each do |entry|
        if entry.name =~ /^pc-book_\d+.csv$/
          entry.extract(csv_filename) { true }
        end
      end
    end
  end

  if @options.transform
    puts 'Transforming CSV to JSON'
    csv = FasterCSV.read(csv_filename)

    # headers start at line 1
    headers = csv[0]
    # set where data lives on each line
    indexes = {}
    indexes['postcode'] = 0
    indexes['suburb'] = 1
    indexes['state'] = 2

    @suburbs = []

    # data starts at line 2
    csv[1..-1].each do |row|
      suburb = { 'postcode_id' => row[indexes['postcode']],
                 'suburb' => row[indexes['suburb']],
                 'state' => row[indexes['state']] }
      @suburbs << suburb
    end

    File.open(json_filename, 'w') do |f|
      f << @suburbs.to_json
    end

  end

end


