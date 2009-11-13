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

  Scenario: Transform to JSON
    Given I have a file ending with ".csv" in "/tmp/8165009"
    When I run "ruby scraper.rb --transform --output-dir=/tmp/8165009"
    Then the command should succeed
    Then I should see a file ending with ".json" in "/tmp/8165009"
    And the JSON in "/tmp/8165009" should have an "sla_code" attribute on every entry
    And the JSON in "/tmp/8165009" should have an "total_businesses" attribute on every entry

  Scenario: Intersect with sla2poa data
    Given I have a file ending with ".json" in "/tmp/8165009"
    And I have an sla2poa mapping file at "/tmp/sla2poa/abs-2905.0.55.001.json"
    When I run "ruby scraper.rb --intersect --mapping /tmp/sla2poa/abs-2905.0.55.001.json --output-dir=/tmp/8165009"
    Then the command should succeed
    Then I should see a file ending with "-intersected.json" in "/tmp/8165009"
    And the intersected JSON in "/tmp/8165009" should have an "postcode" attribute on every entry

  Scenario: Intersect with sla2poa data without specifying mapping file
    When I run "ruby scraper.rb --intersect --output-dir=/tmp/8165009"
    Then the command should fail


