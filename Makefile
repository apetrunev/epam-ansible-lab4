CUR_DIR := $(shell pwd)
PKGS := ansible bash-completion git device-mapper-persistent-data lvm2 python3 vim yum-utils
AWX_LINK := https://github.com/ansible/awx.git
AWX_VERS := 17.1.0
DOCKER_REPO := https://download.docker.com/linux/centos/docker-ce.repo
DOCKER_PKGS := docker-ce docker-ce-cli containerd.io

.ONESHELL:
deps:
	sudo yum install -y epel-release
	sudo yum install -y $(PKGS)
	sudo yum-config-manager --add-repo $(DOCKER_REPO)
	sudo yum install -y $(DOCKER_PKGS)
	sudo systemctl enable --now docker
	sudo usermod -aG docker $$(whoami)
	newgrp docker && sudo pip3 install docker-compose
	sudo ln -sf /usr/bin/python3 /usr/bin/python
	sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

install:
	if ! test -d $(CUR_DIR)/awx; then
	  git clone -b $(AWX_VERS) $(AWX_LINK)
	else true; fi
	if ! test -f $(CUR_DIR)/awx/installer/inventory.bk; then
	  cp -vp $(CUR_DIR)/awx/installer/inventory $(CUR_DIR)/awx/installer/inventory.bk
	else false; fi 
	sed -i -E 's/#[ ]*admin_password=(.*)/admin_password=\1/g' $(CUR_DIR)/awx/installer/inventory 
	sed -i -E 's/#[ ]*project_data_dir=(.*)/project_data_dir=\1/g' $(CUR_DIR)/awx/installer/inventory
	sudo setenforce 0
	sudo sed -i -E 's/SELINUX=.*/SELINUX=disabled/g' /etc/sysconfig/selinux
	(cd $(CUR_DIR)/awx/installer/ && ansible-playbook -i inventory install.yml) 
