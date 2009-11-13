Feature: Australia Post Postcode/Suburb database
  To make postcode data useful
  A lookup table of postcodes and suburbs
  Must be created

  Scenario: Downloading zipped data
    When I run "ruby auspost-suburbs.rb --download --output-dir=/tmp/auspost-suburbs"
    Then the command should succeed
    Then I should see a file ending with ".zip" in "/tmp/auspost-suburbs"

  Scenario: Extracting zipped data
    Given I have a file ending with ".zip" in "/tmp/auspost-suburbs"
    When I run "ruby auspost-suburbs.rb --unzip --output-dir=/tmp/auspost-suburbs"
    Then the command should succeed
    Then I should see a file ending with ".csv" in "/tmp/auspost-suburbs"

  Scenario: Transform to JSON
    Given I have a file ending with ".csv" in "/tmp/auspost-suburbs"
    When I run "ruby auspost-suburbs.rb --transform --output-dir=/tmp/auspost-suburbs"
    Then the command should succeed
    Then I should see a file ending with ".json" in "/tmp/auspost-suburbs"
    And the JSON in "/tmp/auspost-suburbs" should have an "postcode_id" attribute on every entry


