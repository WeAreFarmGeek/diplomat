# frozen_string_literal: true

require 'bundler/setup'
Bundler.setup

require 'json'
require 'base64'

if ENV['CI'] == true
  require 'simplecov'
  SimpleCov.start
end

require 'diplomat'
require 'fakes-rspec'
require 'webmock/rspec'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
