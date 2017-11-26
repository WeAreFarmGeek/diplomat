require 'bundler/setup'
Bundler.setup

require 'json'
require 'base64'
require 'diplomat'
require 'fakes-rspec'

if ENV['CI']
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
end

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
