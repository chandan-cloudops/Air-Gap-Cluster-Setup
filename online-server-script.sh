#!/bin/bash

# Variables
OFFLINE_SERVER_IP="10.0.2.148"
KEY_FILE="terra.pem"  # Specify the path to your private key file
#MP_ACCOUNT_KEY="mp-account.pem" # Specify the path to your mp-account.pem file

# Error function
function check_error {
    if [ $? -ne 0 ]; then
        echo "Error occurred, exiting..."
        exit 1
    fi
}

# Step 1: Install required packages
sudo apt-get update
sudo apt-get -y install \
  apt-transport-https \
  ca-certificates \
  curl \
  gnupg \
  lsb-release \
  sshfs
check_error

# Step 2: Download Docker
mkdir -p ~/lr-airgap/docker-ce
cd ~/lr-airgap/docker-ce

# Add Docker’s official GPG key:
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
# set up the repository:
echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
$(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
check_error

sudo apt-get update
# Fix potential GPG error
sudo chmod a+r /etc/apt/keyrings/docker.gpg
check_error

# Download Docker packages
sudo apt-get download docker-ce docker-ce-cli containerd.io docker-compose-plugin
check_error

# Download cri-dockerd
wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.14/cri-dockerd_0.3.14.3-0.ubuntu-jammy_amd64.deb
check_error

# Step 3: Download Kubernetes
mkdir -p ~/lr-airgap/kube
cd ~/lr-airgap/kube

# Add the Kubernetes repository and update package lists
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
check_error

# Download specific versions of the packages
sudo apt-get download kubelet=1.29.5-1.1 kubeadm=1.29.5-1.1 kubectl=1.29.5-1.1 cri-tools=1.29.0-1.1 conntrack ebtables kubernetes-cni socat selinux-utils
check_error

# Step 4: Package all downloaded files
cd
tar -czvf lr-d4r-k8s.tar.gz lr-airgap
check_error

# Step 5: Download required Kubernetes images
mkdir -p ~/k8s-images
cd ~/k8s-images

# Pull required Kubernetes images
sudo docker pull registry.k8s.io/kube-apiserver:v1.29.5
sudo docker pull registry.k8s.io/kube-controller-manager:v1.29.5
sudo docker pull registry.k8s.io/kube-scheduler:v1.29.5
sudo docker pull registry.k8s.io/kube-proxy:v1.29.5
sudo docker pull registry.k8s.io/coredns/coredns:v1.11.1
sudo docker pull registry.k8s.io/pause:3.9
sudo docker pull registry.k8s.io/etcd:3.5.12-0
check_error

# Save Docker images to tar files
sudo docker save registry.k8s.io/kube-apiserver:v1.29.5 > kube-apiserver_v1.29.5.tar
sudo docker save registry.k8s.io/kube-controller-manager:v1.29.5 > kube-controller-manager_v1.29.5.tar
sudo docker save registry.k8s.io/kube-scheduler:v1.29.5 > kube-scheduler_v1.29.5.tar
sudo docker save registry.k8s.io/kube-proxy:v1.29.5 > kube-proxy_v1.29.5.tar
sudo docker save registry.k8s.io/coredns/coredns:v1.11.1 > coredns_v1.11.1.tar
sudo docker save registry.k8s.io/pause:3.9 > pause_3.9.tar
sudo docker save registry.k8s.io/etcd:3.5.12-0 > etcd_3.5.12-0.tar
check_error

# Package all image tar files
cd
tar -czvf k8s-images.tar.gz k8s-images/
check_error

# Download Flannel
cd
mkdir -p ~/flannel
cd ~/flannel
sudo wget https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
check_error

sudo docker pull docker.io/flannel/flannel-cni-plugin:v1.4.1-flannel1
sudo docker pull docker.io/flannel/flannel:v0.25.2
sudo docker save docker.io/flannel/flannel-cni-plugin:v1.4.1-flannel1 > flannel-cni-plugin-v1.4.1-flannel1.tar
sudo docker save docker.io/flannel/flannel:v0.25.2 > flannel-v0.25.2.tar
check_error

# Package Flannel files
cd
tar -czvf flannel.tar.gz flannel/
check_error

# # Transfer files to the offline server
 #scp -i "$KEY_FILE" flannel.tar.gz  flannel-cni-plugin-v1.4.1-flannel1.tar flannel-v0.25.2.tar ubuntu@"$OFFLINE_SERVER_IP":/home/ubuntu/
# check_error

# Additional steps...
# Download nginx and other required files, transfer them to the offline server, etc.
cd
mkdir -p ~/nginx
cd ~/nginx
#sudo wget https://github.com/kubernetes/ingress-nginx/blob/main/deploy/static/provider/baremetal/deploy.yaml
sudo  wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.1/deploy/static/provider/baremetal/deploy.yaml

check_error

sudo docker pull  registry.k8s.io/ingress-nginx/controller:v1.10.1   
sudo docker pull  registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.1        

sudo docker save registry.k8s.io/ingress-nginx/controller:v1.10.1 > nginx-controller-v1.10.1.tar
sudo docker save registry.k8s.io/ingress-nginx/kube-webhook-certgen:v1.4.1 > kube-webhook-certgen-v1.4.1.tar
check_error


cd
tar -czvf nginx.tar.gz nginx

#scp -i "$KEY_FILE" nginx.tar.gz  ubuntu@"$OFFLINE_SERVER_IP":/home/ubuntu/

check_error