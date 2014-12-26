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
        require_relative 'config'
        Config
      end

      provisioner(:hostsupdate) do
        require_relative 'provisioner'
        Provisioner
      end

      action_hook(:hostsupdate, :machine_action_resume) do |hook|
        require_relative 'action'
        hook.append(Action.add)
      end

      action_hook(:hostsupdate, :machine_action_suspend) do |hook|
        require_relative 'action'
        hook.prepend(Action.remove)
      end

      action_hook(:hostsupdate, :machine_action_halt) do |hook|
        require_relative 'action'
        hook.prepend(Action.remove)
      end

      action_hook(:hostsupdate, :machine_action_destroy) do |hook|
        require_relative 'action'
        hook.prepend(Action.remove)
      end

    end
  end
end
