require "bundler/setup"
Bundler.setup

require 'rspec/core/rake_task'
require 'cucumber'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new(:spec)
Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = "features --format pretty"
end

desc "Run a bootstrapped consul server for testing"
task :consul do
  system("consul agent -server -bootstrap -data-dir=/tmp")
end

task :default => :spec
