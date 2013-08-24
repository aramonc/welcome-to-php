Vagrant.configure("2") do |config|
  config.vm.box = "raring32"
  config.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/raring/current/raring-server-cloudimg-i386-vagrant-disk1.box"

  config.vm.network :private_network, ip: "192.168.33.10"
    config.ssh.forward_agent = true

  config.vm.provider :virtualbox do |v|
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
    v.customize ["modifyvm", :id, "--memory", 1024]
    v.customize ["modifyvm", :id, "--name", "welcome-to-php"]
    v.gui = true
  end

  config.vm.hostname = "welcome-to-php.dev"
  
  config.vm.synced_folder "./", "/vagrant", id: "vagrant-root" 
  config.vm.provision :shell, :inline =>
    "if [[ ! -f /apt-get-run ]]; then sudo apt-get update && sudo touch /apt-get-run; fi"


  config.vm.provision :shell, :inline => 'echo -e "mysql_root_password=vagrant
controluser_password=awesome" > /etc/phpmyadmin.facts;'

  config.vm.provision :puppet do |puppet|
    puppet.manifests_path = "puppet/manifests"
    puppet.module_path = "puppet/modules"
    puppet.options = ['--verbose']
  end
end
