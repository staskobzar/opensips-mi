require "bundler/gem_tasks"
require "rake/clean"
require 'opensips/mi/version'
require 'rspec/core/rake_task'

require "rdoc/task"
Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'rdoc'
  rd.main = "README.md"
  rd.rdoc_files.include("README.md","lib/**/*.rb")
  rd.title = "OpenSIPs management interface " << Opensips::MI::VERSION
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
