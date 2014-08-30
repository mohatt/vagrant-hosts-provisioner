require "vagrant"

# This is a sanity check to make sure no one is attempting to install
# this into an early Vagrant version.
if Vagrant::VERSION < "1.5.0"
  raise "Vagrant HostsProvisioner plugin is only compatible with Vagrant 1.5+"
end

module VagrantPlugins
  module HostsProvisioner
    class Plugin < Vagrant.plugin('2')
      name 'HostsProvisioner'
      description <<-DESC
      A Vagrant provisioner for managing the /etc/hosts file of the host and guest machines.
      DESC

      config(:hostsupdate, :provisioner) do
        require File.expand_path("../config", __FILE__)
        Config
      end

      provisioner(:hostsupdate) do
        require File.expand_path("../provisioner", __FILE__)
        Provisioner
      end
    end
  end
end
