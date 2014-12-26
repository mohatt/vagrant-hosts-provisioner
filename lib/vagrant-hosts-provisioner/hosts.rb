require 'tempfile'

module VagrantPlugins
  module HostsProvisioner
    class Hosts

      def initialize(machine, config)
        @machine = machine
        @config = config
      end

      def add
        # Update the guest machine if manage_guest is enabled
        if @config.manage_guest
          update_guest
        end

        # Update the host machine if manage_host is enabled
        if @config.manage_host
          update_host(false)
        end
      end

      def remove
        if @config.manage_host
          update_host(true)
        end
      end

      def update_guest
        return unless @machine.communicate.ready?

        handle_comm(:stdout, I18n.t("vagrant_hostsprovisioner.provisioner.update_guest"))

        if (@machine.communicate.test("uname -s | grep SunOS"))
          realhostfile = '/etc/inet/hosts'
          move_cmd = 'mv'
        elsif (@machine.communicate.test("test -d $Env:SystemRoot"))
          windir = ""
          @machine.communicate.execute("echo %SYSTEMROOT%", {:shell => :cmd}) do |type, contents|
            windir << contents.gsub("\r\n", '') if type == :stdout
          end
          realhostfile = "#{windir}\\System32\\drivers\\etc\\hosts"
          move_cmd = 'mv -force'
        else
          realhostfile = '/etc/hosts'
          move_cmd = 'mv -f'
        end

        # download and modify file with Vagrant-managed entries
        file = @machine.env.tmp_path.join("hosts.#{@machine.name}")
        @machine.communicate.download(realhostfile, file)
        if update_file(file, false, false)
          # upload modified file and remove temporary file
          @machine.communicate.upload(file, '/tmp/hosts')
          @machine.communicate.sudo("#{move_cmd} /tmp/hosts #{realhostfile}")
          handle_comm(:stdout, I18n.t("vagrant_hostsprovisioner.provisioner.hosts_file_updated", {:file => realhostfile}))
        end

        begin
          FileUtils.rm(file)
         rescue Exception => e
        end
      end

      def update_host(clean)
        # copy and modify hosts file on host with Vagrant-managed entries
        file = @machine.env.tmp_path.join('hosts.local')

        if clean == true
          handle_comm(:stdout, I18n.t("vagrant_hostsprovisioner.provisioner.clean_host"))
        else
          handle_comm(:stdout, I18n.t("vagrant_hostsprovisioner.provisioner.update_host"))
        end

        if WindowsSupport.windows?
          # lazily include windows Module
          class << self
            include WindowsSupport unless include? WindowsSupport
          end

          hosts_location = "#{ENV['WINDIR']}\\System32\\drivers\\etc\\hosts"
          copy_proc = Proc.new { windows_copy_file(file, hosts_location) }
        else
          hosts_location = '/etc/hosts'
          copy_proc = Proc.new { `sudo cp #{file} #{hosts_location}` }
        end

        FileUtils.cp(hosts_location, file)
        if update_file(file, true, clean)
          copy_proc.call
          handle_comm(:stdout, I18n.t("vagrant_hostsprovisioner.provisioner.hosts_file_updated", {:file => hosts_location}))
        end
      end

      def update_file(file, include_id, clean)
        file = Pathname.new(file)
        old_file_content = file.read
        new_file_content = update_content(old_file_content, include_id, clean)
        file.open('w') { |io| io.write(new_file_content) }
        old_file_content != new_file_content
      end

      def update_content(file_content, include_id, clean)
        id = include_id ? " id: #{read_or_create_id}" : ""
        header = "## vagrant-hosts-provisioner-start#{id}\n"
        footer = "## vagrant-hosts-provisioner-end\n"
        body = clean ? "" : get_hosts_file_entry
        get_new_content(header, footer, body, file_content)
      end

      def get_hosts_file_entry
        # Get the vm ip address
        ip = get_ip_address

        # Return empy string if we don't have an ip address
        if ip === nil
          handle_comm(:stderr, I18n.t("vagrant_hostsprovisioner.error.no_vm_ip"))
          return ''
        end

        hosts = []

        # Add the machine hostname
        unless @config.hostname === false
          hosts.push(@config.hostname || @machine.config.vm.hostname || @machine.name)
        end

        # Add the defined aliases
        hosts.concat(@config.aliases)

        # Add the contents of the defined hosts files
        if @config.files.count > 0
          hosts.concat(get_files_data)
        end

        # Remove duplicates
        hosts = hosts.uniq

        # Limit the number of hosts per line to 8
        lines = []
        hosts.each_slice(8) do |chnk|
          lines.push("#{ip}\t" + chnk.join(' ').strip)
        end

        # Join lines
        hosts = lines.join("\n").strip

        "#{hosts}\n"
      end

      def get_files_data
        require 'json'
        data = []
        @config.files.each do |file|
          if file.kind_of?(String) && file != ""
            file_path = File.join(@machine.env.root_path, file)
            if File.exist?(file_path)
              file_data = JSON.parse(File.read(file_path))
              data.concat([ file_data ].flatten)
            else
              handle_comm(:stderr, I18n.t("vagrant_hostsprovisioner.error.file_not_found", {:file => file.to_s}))
            end
          end
        end
        data.collect(&:strip)
      end

      def get_ip_address
        ip = nil
        @machine.config.vm.networks.each do |network|
          key, options = network[0], network[1]
          ip = options[:ip] if key == :private_network
          break if ip
        end
        # If no ip is defined in private_network then use the ssh host ip instead
        ip || (@machine.ssh_info ? @machine.ssh_info[:host] : nil)
      end

      def get_new_content(header, footer, body, old_content)
        if body.empty?
          block = "\n"
        else
          block = "\n\n" + header + body + footer + "\n"
        end
        # Pattern for finding existing block
        header_pattern = Regexp.quote(header)
        footer_pattern = Regexp.quote(footer)
        pattern = Regexp.new("\n*#{header_pattern}.*?#{footer_pattern}\n*", Regexp::MULTILINE)
        # Replace existing block or append
        old_content.match(pattern) ? old_content.sub(pattern, block) : old_content.rstrip + block
      end

      def read_or_create_id
        file = Pathname.new("#{@machine.env.local_data_path}/hostsprovisioner/#{@machine.name}")
        if (file.file?)
          id = file.read.strip
        else
          id = SecureRandom.uuid
          file.dirname.mkpath
          file.open('w') { |f| f.write(id) }
        end
        id + "-" + @config.id.to_s
      end

      ## Windows support for copying files, requesting elevated privileges if necessary
      module WindowsSupport
        require 'rbconfig'

        def self.windows?
          RbConfig::CONFIG['host_os'] =~ /mswin|mingw|cygwin/
        end

        require 'win32ole' if windows?

        def windows_copy_file(source, dest)
          begin
            # First, try Ruby copy
            FileUtils.cp(source, dest)
          rescue Errno::EACCES
            # Access denied, try with elevated privileges
            windows_copy_file_elevated(source, dest)
          end
        end

        private

        def windows_copy_file_elevated(source, dest)
          # copy command only supports backslashes as separators
          source, dest = [source, dest].map { |s| s.to_s.gsub(/\//, '\\') }

          # run 'cmd /C copy ...' with elevated privilege, minimized
          copy_cmd = "copy \"#{source}\" \"#{dest}\""
          WIN32OLE.new('Shell.Application').ShellExecute('cmd', "/C #{copy_cmd}", nil, 'runas', 7)

          # Unfortunately, ShellExecute does not give us a status code,
          # and it is non-blocking so we can't reliably compare the file contents
          # to see if they were copied.
          #
          # If the user rejects the UAC prompt, vagrant will silently continue
          # without updating the hostsfile.
        end
      end

      # This handles outputting the communication data back to the UI
      def handle_comm(type, data)
        if [:stderr, :stdout].include?(type)
          # Output the data with the proper color based on the stream.
          color = type == :stdout ? :green : :red

          # Clear out the newline since we add one
          data = data.chomp
          return if data.empty?

          options = {}
          options[:color] = color

          @machine.ui.info(data.chomp, options)
        end
      end

    end
  end
end
