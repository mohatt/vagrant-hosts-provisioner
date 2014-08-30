require 'tempfile'

module VagrantPlugins
  module HostsProvisioner
    class Provisioner < Vagrant.plugin('2', :provisioner)
      #include HostsFile

      def initialize(machine, config)
        super(machine, config)

      end

      def provision
        # Update the guest machine if manage_guest is enabled
        if @config.manage_guest?
          update_guest
        end
        
        # Update the host machine if manage_host is enabled
        if @config.manage_host?
          update_host
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
        if update_file(file, false)
          # upload modified file and remove temporary file
          @machine.communicate.upload(file, '/tmp/hosts')
          @machine.communicate.sudo("#{move_cmd} /tmp/hosts #{realhostfile}")
        end

        begin
          FileUtils.rm(file) 
        rescue Exception => e
        end
      end

      def update_host
        # copy and modify hosts file on host with Vagrant-managed entries
        file = @machine.env.tmp_path.join('hosts.local')

        handle_comm(:stdout, I18n.t("vagrant_hostsprovisioner.provisioner.update_host"))

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
        if update_file(file, true)
          copy_proc.call
        end
      end

      def update_file(file, include_id)
        file = Pathname.new(file)
        old_file_content = file.read
        new_file_content = update_content(old_file_content, include_id)
        file.open('w') { |io| io.write(new_file_content) }
        old_file_content != new_file_content
      end

      def update_content(file_content, include_id)
        id = include_id ? " id: #{read_or_create_id}" : ""
        header = "## vagrant-hostmanager-start#{id}\n"
        footer = "## vagrant-hostmanager-end\n"
        body = get_hosts_file_entry
        get_new_content(header, footer, body, file_content) 
      end

      def get_hosts_file_entry
        ip = get_ip_address
        host = @config.hostname || @machine.config.vm.hostname || @machine.name
        aliases = @config.aliases.join(' ').chomp
        if ip != nil
          "#{ip}\t#{host} #{aliases}\n"
        end
      end

      def get_ip_address
        ip = nil
        @machine.config.vm.networks.each do |network|
          key, options = network[0], network[1]
          ip = options[:ip] if key == :private_network
          break if ip
        end
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
        file = Pathname.new("#{@machine.env.local_data_path}/hostmanager/id")
        if (file.file?)
          id = file.read.strip
        else
          id = SecureRandom.uuid
          file.dirname.mkpath
          file.open('w') { |io| io.write(id) }
        end
        id
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
