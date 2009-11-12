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

Then /^the JSON in "([^\"]*)" should have lat\/lng co\-ordinates$/ do |directory|
  filename = "#{directory}/abs-8165009-normalised.json"
  File.exists?(filename).should be_true

  json = File.new(filename, 'r')
  parser = Yajl::Parser.new
  data = parser.parse(json)

  data.detect { |entry| entry['lat'] || entry['lng'] }.should_not be_nil
end

