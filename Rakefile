require 'bundler/setup'
Bundler.setup

begin
  require 'rubocop/rake_task'

  desc 'Run Ruby style checks'
  RuboCop::RakeTask.new(:style)
rescue LoadError => e
  puts ">>> Gem load error: #{e}, omitting style" unless ENV['CI']
end

begin
  require 'rspec/core/rake_task'

  desc 'Run RSpec examples'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError => e
  puts ">>> Gem load error: #{e}, omitting spec" unless ENV['CI']
end

begin
  require 'cucumber'
  require 'cucumber/rake/task'

  desc 'Run Cucumber features'
  Cucumber::Rake::Task.new(:features) do |t|
    t.cucumber_opts = 'features --format pretty'
  end
rescue LoadError => e
  puts ">>> Gem load error: #{e}, omitting spec" unless ENV['CI']
end

desc 'Run a bootstrapped consul server for testing'
task :consul do
  system('consul agent -server -bootstrap -data-dir=/tmp')
end

task default: %w(style spec)
