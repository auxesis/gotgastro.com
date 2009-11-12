Feature: Australia Post sla2poa
  To correctly aggregate and correlate NSW FA + ABS data
  We must compare it to a list of sla2poa

  Scenario: Downloading zipped data
    When I run "ruby sla2poa.rb --download --output-dir=/tmp/sla2poa"
    Then the command should succeed
    Then I should see a file ending with ".zip" in "/tmp/sla2poa"

  Scenario: Extracting zipped data
    Given I have a file ending with ".zip" in "/tmp/sla2poa"
    When I run "ruby sla2poa.rb --unzip --output-dir=/tmp/sla2poa"
    Then the command should succeed
    Then I should see a file ending with ".csv" in "/tmp/sla2poa"

  Scenario: Transform to JSON
    Given I have a file ending with ".csv" in "/tmp/sla2poa"
    When I run "ruby sla2poa.rb --transform --output-dir=/tmp/sla2poa"
    Then the command should succeed
    Then I should see a file ending with ".json" in "/tmp/sla2poa"

