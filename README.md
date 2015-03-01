# VagrantPlugins::HostsProvisioner

A Vagrant provisioner for managing the /etc/hosts file of the host and guest machines.
## Installation

Install into vagrant's isolated RubyGems instance using:

    $ vagrant plugin install vagrant-hosts-provisioner

## Usage

Example configuration:

```ruby
config.vm.provision :hostsupdate, run: 'always' do |host|
	host.hostname = 'demo-hostname'
	host.manage_guest = true
	host.manage_host = true
	host.aliases = [
		'hostname-aliase1',
		'hostname-aliase2'
	]
	host.files = [
		'config/hosts.json'
	]
end
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
