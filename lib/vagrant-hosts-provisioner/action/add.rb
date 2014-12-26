module VagrantPlugins
  module HostsProvisioner
    module Action
      class Add

        def initialize(app, env)
          @app = app
          @machine = env[:machine]
          @config = @machine.env.vagrantfile.config
        end

        def call(env)
          @config.vm.provisioners.each do |provisioner|
            if provisioner.name == :hostsupdate
              Hosts.new(@machine, provisioner.config).add
            end
          end
          @app.call(env)
        end

      end
    end
  end
end
