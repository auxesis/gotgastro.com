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
  Dir.glob("#{directory}/*#{extension}").size.should > 0
end

Then /^the (\w*\s*)JSON in "([^\"]*)" should have an "([^\"]*)" attribute on every entry$/ do |type, directory, attribute|
  filename = "#{directory}/auspost-postcodes-and-suburbs#{type.blank? ? '' : "-#{type.strip}"}.json"
  File.exists?(filename).should be_true
  
  json = File.new(filename, 'r')
  parser = Yajl::Parser.new
  data = parser.parse(json)

  data.each do |entry|
    entry[attribute].should_not be_nil
  end
end

