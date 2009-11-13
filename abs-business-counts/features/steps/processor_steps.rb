When /^I run "([^\"]*)"$/ do |command|
  @result = system(command)
end

Then /^the command should succeed$/ do 
  @result.should be_true
end

Then /^the command should fail$/ do 
  @result.should be_false
end

Then /^I should see a file ending with "([^\"]*)" in "([^\"]*)"$/ do |extension, directory|
  Dir.glob("#{directory}/*#{extension}").size.should > 0
end

Given /^I have a file ending with "(.+)" in "([^\"]*)"$/ do |extension, directory|
  Dir.glob("#{directory}/abs-8165009#{extension}").size.should > 0
end

Then /^the (\w*\s*)JSON in "([^\"]*)" should have an "([^\"]*)" attribute on every entry$/ do |type, directory, attribute|
  filename = "#{directory}/abs-8165009#{type.blank? ? '' : "-#{type.strip}"}.json"
  File.exists?(filename).should be_true
  
  json = File.new(filename, 'r')
  parser = Yajl::Parser.new
  data = parser.parse(json)

  data.each do |entry|
    entry[attribute].should_not be_nil
  end
end

Given /^I have an sla2poa mapping file at "([^\"]*)"$/ do |filename|
  File.exists?(filename).should be_true

  json = File.new(filename, 'r')
  parser = Yajl::Parser.new
  data = parser.parse(json)

  data.each do |entry|
    entry['sla_name'].should_not be_nil
    entry['sla_code'].should_not be_nil
    entry['poa_code'].should_not be_nil
  end
end
