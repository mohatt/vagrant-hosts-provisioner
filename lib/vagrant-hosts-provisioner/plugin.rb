module VagrantPlugins
  module HostsProvisioner
    class Plugin < Vagrant.plugin('2')
      name 'HostsProvisioner'
      description <<-DESC
        A Vagrant provisioner for managing the /etc/hosts file of the host and guest machines.
      DESC

    end
  end
end