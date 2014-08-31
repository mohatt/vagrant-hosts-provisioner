require 'bundler/setup'
require 'bundler/gem_helper'

# Immediately sync all stdout so that tools like buildbot can
# immediately load in the output.
$stdout.sync = true
$stderr.sync = true

# Change to the directory of this file.
Dir.chdir(File.expand_path("../", __FILE__))

# This installs the tasks that help with gem creation and
# publishing.
Bundler::GemHelper.install_tasks

task :test_single do
  sh 'bash test/single/test.sh'
end

task :test_multi do
  sh 'bash test/multi/test.sh'
end
