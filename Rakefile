require "bundler/setup"
Bundler.setup
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

desc "Run a bootstrapped consul server for testing"
task :consul do
  system("consul agent -server -bootstrap -data-dir=/tmp")
end

task :default => :spec
