#/usr/bin/env ruby

$:.insert(0, File.expand_path(File.join(File.dirname(__FILE__), '..')))

require 'scraper'

describe Crawler do
  before(:each) do 
    @url = "http://www.foodauthority.nsw.gov.au/aboutus/offences/prosecutions/"
    @type = :prosecutions
  end

  it "should require options on initialisation" do
    lambda { 
      Crawler.new
    }.should raise_error
  end

  it "should set @type and @url on initialisation" do 
    c = Crawler.new(:url => @url, :type => @type)
    c.url.should =~ /^.+$/
    c.type.should == :prosecutions
  end

  it "should serialise html" do 
    c = Crawler.new(:url => @url, :type => @type)
    c.serialise('<html></html>', 'tmp/foo').should be_true
  end

  it "should be able to get a page" do 
    c = Crawler.new(:url => @url, :type => @type)
    c.get_page("tmp/test-page-for-open-uri.html").should =~ /<.+>.+<\/.+>/
  end

  it "should get an index of penalties" do 
    c = Crawler.new(:url => 'tmp/test-penalties.html', :type => :penalties)
    notices = c.get_index
    notices.class.should == Array
    notices.each do |n|
      n.has_key?(:id).should == true
      n.has_key?(:url).should == true
    end
  end

  it "should get an index of prosecutions" do
    c = Crawler.new(:url => 'tmp/test-prosecutions.html', :type => :prosecutions)
    notices = c.get_index
    notices.class.should == Array
    notices.each do |n|
      n.has_key?(:id).should == true
      n.has_key?(:url).should == true
    end
  end

  it "should extract id + urls from penalties index" do 
    c = Crawler.new(:url => 'tmp/test-penalties.html', :type => :penalties)
    doc = Nokogiri::HTML(c.get_page(c.url))
    notices = c.filter_penalties(doc)
    notices.each do |n|
      n[:id].should =~ /^\d+$/
      n[:url].should =~ /#{n[:id]}/ # id is somewhere in the url
    end
  end

  it "should extract id + urls from prosecutions index" do 
    c = Crawler.new(:url => 'tmp/test-prosecutions.html', :type => :prosecutions)
    doc = Nokogiri::HTML(c.get_page(c.url))
    notices = c.filter_prosecutions(doc)
    notices.each do |n|
      n[:id].should =~ /^\w+-\w+/
      n[:url].should =~ /#{n[:id]}/ # id is somewhere in the url
    end
  end


end

# override command line output
def puts(*args)
end
