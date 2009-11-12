Feature: 8165009 processor
  To make ABS data usable to the public
  We must extract it
  And normalise it
  And geocode it
  And republish it

  Scenario: Downloading zipped data
    When I run "ruby scraper.rb --download --output-dir=/tmp/8165009"
    Then the command should succeed
    Then I should see a file ending with ".zip" in "/tmp/8165009"

  Scenario: Extracting zipped data
    Given I have a file ending with ".zip" in "/tmp/8165009"
    When I run "ruby scraper.rb --unzip --output-dir=/tmp/8165009"
    Then the command should succeed
    Then I should see a file ending with ".xls" in "/tmp/8165009"

  Scenario: Extracting zipped data that hasn't been downloaded
    Given I don't have a ".zip" in "/tmp/8165009"
    When I run "ruby scraper.rb --extract --output-dir=/tmp/8165009"
    Then the command should fail

  Scenario: Convert to CSV
    Given I have a file ending with ".xls" in "/tmp/8165009"
    When I run "ruby scraper.rb --convert --output-dir=/tmp/8165009"
    Then the command should succeed
    Then I should see a file ending with ".csv" in "/tmp/8165009"

  #Scenario: Run without having Gnumeric installed
    #When I run "ruby scraper.rb --convert --output-dir=/tmp/8165009"

  Scenario: Transform to JSON
    Given I have a file ending with ".csv" in "/tmp/8165009"
    When I run "ruby scraper.rb --transform --output-dir=/tmp/8165009"
    Then the command should succeed
    Then I should see a file ending with ".json" in "/tmp/8165009"

  Scenario: Normalise JSON
    Given I have a file ending with ".json" in "/tmp/8165009"
    When I run "ruby scraper.rb --normalise --output-dir=/tmp/8165009"
    Then the command should succeed
    Then I should see a file ending with "normalised.json" in "/tmp/8165009"

  Scenario: Geocode JSON
    Given I have a file ending with "-normalised.json" in "/tmp/8165009"
    When I run "ruby scraper.rb --geocode --output-dir=/tmp/8165009"
    Then the command should succeed
    And I should see a file ending with ".json" in "/tmp/8165009"
    And the JSON in "/tmp/8165009" should have lat/lng co-ordinates




