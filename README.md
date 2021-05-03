---

title: Build Kubernetes QEMU/KVM Image with Packer
date: '2020-03-16 15:24:00'
tags:
- kubernetes
- virtualization
- kvm
- english
---

## Initial Source
This content was initially sourced from [rizkidoank/rizkidoank.github.io](https://github.com/rizkidoank/rizkidoank.github.io/blob/master/content/posts/2020-03-16-build-kubernetes-qemu-kvm-image-with-packer.markdown) however that was a ubuntu 18.04 build with an earlier version of Kubernetes.
The current build is ubuntu 20.04 with Kubernetes 1.21


[Packer](https://packer.io/) is a tools to automate creation of multiple machine images build by [Hashicorp](https://www.hashicorp.com). Its support multiple builders such as AWS EC2, DigitalOcean, LXD, VMWare, QEMU, etc. In this post, I will share how to create a packer template to build kubernetes image for QEMU/KVM on top of Ubuntu minimal cloud image based on my homelab setup.

## Prerequisites
- packer
- cloud-localds (from `cloud-image-utils` in ubuntu)
- QEMU/KVM enabled host

## Step by Step
1.  Ensure you have QEMU/KVM enabled host, and also packer installed in your machine. If you use Linux, you could use following commands:

    ```
    export PACKER_VERSION=1.5.4
    curl -SL https://releases.hashicorp.com/packer/$(PACKER_VERSION)/packer_$(PACKER_VERSION)_linux_amd64.zip -o packer_$(PACKER_VERSION)_linux_amd64.zip
    unzip packer_$(PACKER_VERSION)_linux_amd64.zip
    sudo mv packer /usr/bin/packer
    ```
2.  Create packer configuration file named [`kubernetes.json`](kubernetes.json)

    Notes the variables section,

    - `image_checksum`, can be found from [SHA256SUMS](https://cloud-images.ubuntu.com/minimal/releases/bionic/release/SHA256SUMS) or use `sha256sum <image_file>`
    - `image_url`, can be local path or http(s) path, in this case we use https path from [ubuntu cloud minimal release](https://cloud-images.ubuntu.com/minimal/releases/bionic/release).
    - `cloud_init_image`, minimal ubuntu cloud image has cloud-init support and need to configured in order to use it properly. We will create the cloud-init image in next step.
    - `ssh_username`, by default ubuntu cloud minimal image use `ubuntu` as default user.
    - `ssh_password`, this value need to be defined in our cloud-init userdata.

3.  Create cloud-init image with following [`userdata.cfg`](userdata.cfg):

    After that, build cloud-init image with following command:
    ```
    # ensure cloud-localds command exist, install cloud-image-utils in ubuntu
    sudo apt-get install cloud-image-utils -y
    cloud-localds cloud-init.img userdata.cfg
    ```

4.  Create Kubernetes setup script, you could follow from [Kubernetes docs](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/) or use [`setup.sh`](setup.sh) script:

    Notes following commands:

    - `kubeadm config images pull`, this command will pull required docker images for kubernetes to run. This will save your time when you bootstrap a cluster, because the docker images are baked to the VM image.
    - `sudo apt-mark hold kubelet kubeadm kubectl`, this command will ensure the mentioned packages are not upgraded to prevent break when auto-upgrade triggered.

5.  Everything is set! The next step is validate the config and then build the image:

    ```
    # might need sudo if user don't have permission to KVM module
    packer validate kubernetes.json
    packer build kubernetes.json
    ```

    The following logs is an output part of packer build process:
    ```
    ==> qemu: Provisioning with shell script: /tmp/packer-shell168629488
    ==> qemu: Halting the virtual machine...
    ==> qemu: Converting hard drive...
    ==> qemu: Error getting file lock for conversion; retrying...
    Build 'qemu' finished.

    ==> Builds finished. The artifacts of successful builds are:
    --> qemu: VM files in directory: build
    ```

6.  Image are ready to use, please note that the size might be too small. You could resize the image with following command `qemu-img resize <IMAGE_FILE> +DESIRED_SIZE`. Let say we want `kubernetes-1584350145.qcow2` which currently has 6GB size, resized to 100GB, then the command will be:

    ```
    qemu-img resize kubernetes-1584350145.qcow2 +92G
    ```
