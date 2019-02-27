require 'bundler/setup'
Bundler.setup

require 'json'
require 'base64'

if ENV['CI'] == true
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

require 'diplomat'
require 'fakes-rspec'
require 'webmock/rspec'

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
