require "bundler/gem_tasks"

task :default => [:test_offline]

#Offline tests only: don't perform tests that require live hardware. 
task :test_offline do
  sh "rspec -Ilib --tag=~online"
end

task :test do
  sh "rspec -Ilib"
end

task :install_adept do

end
