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

