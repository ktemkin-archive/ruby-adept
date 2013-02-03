require "bundler/gem_tasks"

task :default => :test_all

task :test_all do
  sh "rspec -Ilib"
end

desc 'Builds the ruby-adept gem.'
task :build do
  sh "gem build ruby-adept.gemspec"
end

desc 'Builds and installs the ruby-adept gem.'
task :install => :build do
  sh "gem install pkg/ruby-adept-#{Adept::VERSION}.gem"
end

desc 'Tags the current version, pushes it GitHub, and pushes the gem.'
task :release => :build do
  sh "git tag v#{Adept::VERSION}"
  sh "git push origin master"
  sh "git push origin v#{Adept::VERSION}"
  sh "git push pkg.ruby-adept-#{Adept::VERSION}.gem"
end
