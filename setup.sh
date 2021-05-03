#!/bin/bash -x

# Add a serial console (We are building for KVM)

sed -i 's#^GRUB_CMDLINE_LINUX_DEFAULT=.*#GRUB_CMDLINE_LINUX_DEFAULT="rootdelay=10 net.ifnames=0 biosdevname=0"#g' /etc/default/grub
sed -i 's#^GRUB_CMDLINE_LINUX=.*#GRUB_CMDLINE_LINUX="console=ttyS0,115200n8 rootdelay=10 net.ifnames=0 biosdevname=0"#g' /etc/default/grub
sed -i 's/^#GRUB_TERMINAL=.*/GRUB_TERMINAL=serial\nGRUB_SERIAL_COMMAND="serial --speed=115200 --unit=0 --word=8 --parity=no --stop=1"/g' /etc/default/grub

update-grub

apt-get update && apt-get upgrade -y && apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common

curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"

apt-get update && apt-get install -y \
  containerd

mkdir -p /etc/containerd
containerd config default  /etc/containerd/config.toml

echo "net.bridge.bridge-nf-call-iptables = 1" >> /etc/sysctl.conf
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf

sysctl --system
swapoff -a
modprobe overlay
modprobe br_netfilter
echo -e "overlay\nbr_netfilter" > /etc/modules-load.d/crio.conf

systemctl daemon-reload
systemctl restart containerd

apt-get install -y \
  kubelet kubeadm kubectl

apt-mark hold kubelet kubeadm kubectl

apt autoclean
rm -Rf /var/cache/apt/*

mkdir -p ~ubuntu/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDaN3jLdekb/QSyHCuIdddnzqnKp5fzynFM4MMusaMmQaZvCq+y9vW1OUZZi48pKXyiSuCnFlzkp8EKuK2al6HH5TJ/ZKwVDsQA+WDhNiE9TZv9DIl4wEBNCxSNjAR6g/5C3gQc2XYPTzEn72RUCzMqg+gcSf3Bu8L5XgCPJ8EksrB9ONuvVCmCATqk66iqgX3Ny6n0jDzQx/YkShhRdgBn5a9RPTLPhtasfT9VepvpZTEj/Pjmf4UFY7+fkWTLW2UwiLvGPMmboS1unlq33fepS4/sviM8XdDqTGp2pNz+MzSTkMPApGVkjhpinUciQ54HIrUy/wS6w3y47O7f5RJl" > ~ubuntu/.ssh/authorized_keys
chown -R ubuntu.ubuntu ~ubuntu
chmod -R 700 ~ubuntu/.ssh

systemctl daemon-reload
systemctl restart kubelet

sleep 30s

kubeadm config images pull
