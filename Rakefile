require 'rubygems'
require 'rake'

require "rspec"
require "rspec/core/rake_task"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name        = "votable_mongoid"
    gem.summary     = %Q{Add Up / Down Voting for Mongoid}
    gem.description = %Q{Add Up / Down Voting for Mongoid}
    gem.email       = "alex@vinova.sg"
    gem.homepage    = "http://github.com/vinova/votable_mongoid"
    gem.authors     = ["Alex Nguyen"]
    gem.files       = Dir.glob("lib/**/*")
    gem.test_files  = []
    gem.add_dependency 'mongoid', '~> 2.0.0.beta'

    gem.add_development_dependency 'ruby-debug'
    gem.add_development_dependency 'bson_ext'
    gem.add_development_dependency 'rspec', '~> 2.0.0.beta.20'
  end
  Jeweler::GemcutterTasks.new

rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

Rspec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = "spec/**/*_spec.rb"
end

task :default => ["spec"]
