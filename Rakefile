require "bundler/gem_tasks"
require "rake/clean"
require 'opensips/mi/version'

require "rdoc/task"
Rake::RDocTask.new do |rd|
  rd.rdoc_dir = 'rdoc'
  rd.main = "README.md"
  rd.rdoc_files.include("README.md","lib/**/*.rb")
  rd.title = "OpenSIPs management interface " << Opensips::MI::VERSION
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

#require 'rcov/rcovtask'
#Rcov::RcovTask.new do |test|
#  test.libs << 'test'
#  test.pattern = 'test/**/test_*.rb'
#  test.verbose = true
#  test.rcov_opts << '--exclude "gems/*"'
#end
