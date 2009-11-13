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
      opts.on('--intersect', "Intersect the 8165009 JSON data with the sla2pos mappings") do 
        options.intersect = true
      end
      opts.on('--mapping FILE', "Mapping file for sla2pos intersection") do |filename|
        options.mapping = filename
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

if __FILE__ == $0 then

  @options = Options.parse(ARGV)

  output_directory = @options.output_directory ? FileUtils.mkdir_p(@options.output_directory) : Dir.mktmpdir
  zip_filename  = File.join(output_directory, "abs-8165009.zip")
  xls_filename  = File.join(output_directory, "abs-8165009.xls")
  csv_filename  = File.join(output_directory, "abs-8165009.csv")
  json_filename = File.join(output_directory, "abs-8165009.json")
  intersected_json_filename = File.join(output_directory, "abs-8165009-intersected.json")

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
    indexes['industry']         = headers.index(headers.grep(/^\s*industry\s*$/i).first)
    indexes['sla_code']         = headers.index(headers.grep(/^\s*sla\s*codes\s*$/i).first)
    indexes['total_businesses'] = headers.index(headers.grep(/^\s*total\s*$/i).first)

    @areas = []

    # data starts at line 9
    csv[8..-1].each do |row|
      if row[indexes['industry']] =~ /ACCOMMODATION CAFES AND RESTAURANTS/i
        area = {'sla_code' => row[indexes['sla_code']], 'total_businesses' => row[indexes['total_businesses']]}
        @areas << area
      end
    end

    File.open(json_filename, 'w') do |f|
      f << @areas.to_json
    end
  end

  if @options.intersect
    areas_json = File.new(json_filename, 'r')
    parser = Yajl::Parser.new
    @areas = parser.parse(areas_json)

    sla2poa_json = File.new(@options.mapping, 'r')
    parser = Yajl::Parser.new
    @sla_mappings = parser.parse(sla2poa_json)

    @sla_mappings.each do |mapping|
      areas_for_mapping = @areas.find_all do |area| 
        area['sla_code'] == mapping['sla_code']
      end

      areas_for_mapping.each do |area|
        area.delete('sla_code')
        area['postcode'] = mapping['poa_code']
      end
    end

    # "unknown" data should be filtered out
    bogus = @areas.find_all { |area| area['sla_code'] =~ /99999999$/ }
    bogus.each { |entry| @areas.delete(entry) }

    File.open(intersected_json_filename, 'w') do |f|
      f << @areas.to_json
    end
  end

end


