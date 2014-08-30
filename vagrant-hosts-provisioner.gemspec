# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-hosts-provisioner/version'

Gem::Specification.new do |spec|
  spec.name          = "vagrant-hosts-provisioner"
  spec.version       = VagrantPlugins::HostsProvisioner::VERSION
  spec.authors       = ["Mohamed Elkholy"]
  spec.email         = ["mkh117@gmail.com"]
  spec.description   = %q{A Vagrant provisioner for managing the /etc/hosts file of the host and guest machines.}
  spec.summary       = spec.description
  spec.homepage      = "https://github.com/mdkholy/Dashboard"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
