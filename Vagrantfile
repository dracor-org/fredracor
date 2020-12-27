# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  config.vm.box = "fedora/33-cloud-base"
  config.vm.box_version = "33.20201019.0"
  # We are mounting fredracor in addition to the default /vagrant folder since
  # that one seems to be Rsync only, probably because auf a mismatch between
  # Virtualbox (6.1.16) and the VBGuestAdditions (6.0.x) available on fedora
  config.vm.synced_folder ".", "/vagrant_fredracor"
  config.vm.synced_folder "../theatre-classique", "/vagrant_sources"
  config.vm.provider "virtualbox" do |vb|
    vb.memory = "4096"
  end

  config.vm.provision "shell", inline: <<-SHELL
    dnf -y install podman
    dnf -y install jing
    # these are for debugging convenience
    dnf -y install httpie
    dnf -y install tig
  SHELL
end
