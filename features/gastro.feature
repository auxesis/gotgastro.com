Feature: scraper + geocoder
  As a discerning consumptor of food
  I want to know if the food I'm eating
  Has not been prepared with care
  In a timely manner

  Scenario: Scraper
    When I run `geocode`
    Then the exit status should be 0

