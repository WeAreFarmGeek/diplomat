Feature: Configuration

  Scenario: I'm Setting up Diplomat with a default config
    Given I am setting up a default diplomat
    Then I should be able to get and put keys

  Scenario: I'm Setting up Diplomat with a custom config
    Given I am setting up a custom diplomat
    Then I should be able to get and put keys
