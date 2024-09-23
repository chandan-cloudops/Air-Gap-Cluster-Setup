#!/bin/bash

# Variables
OFFLINE_SERVER_IP="10.0.2.148"
KEY_FILE="terra.pem"  # Specify the path to your private key file

# Error function
function check_error {
    if [ $? -ne 0 ]; then
        echo "Error occurred, exiting..."
        exit 1
    fi
}

# Step 1: Copy the tar files to the offline machine
scp -i "$KEY_FILE" lr-d4r-k8s.tar.gz k8s-images.tar.gz flannel.tar.gz nginx.tar.gz ubuntu@"$OFFLINE_SERVER_IP":/home/ubuntu/
check_error

# Step 2: Unpack the files and install Docker & Kubernetes
ssh -i "$KEY_FILE" ubuntu@"$OFFLINE_SERVER_IP" << 'ENDSSH'
cd /home/ubuntu || exit

tar -xzvf lr-d4r-k8s.tar.gz
tar -xzvf k8s-images.tar.gz
tar -xzvf flannel.tar.gz 
tar -xzvf nginx.tar.gz

# Step 3: Install Docker
cd airgap/docker-ce || exit
sudo dpkg -i *

sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
sudo systemctl daemon-reload
sudo docker version
#sudo systemctl status docker
#sudo systemctl status cri-dockerd
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
#sudo systemctl status cri-docker.service
sudo systemctl start cri-docker.service
#sudo systemctl status cri-docker.service
check_error

# Step 4: Install Kubernetes
cd ../kube || exit
sudo dpkg -i *
sudo apt-mark hold kubelet kubeadm kubectl
check_error

# Step 5: Load Kubernetes images
cd ../../k8s-images || exit
for x in *.tar; do
    sudo docker load < "$x" && echo "Loaded from file $x"
done
check_error

# Additional steps...
# Load flannel and nginx images, configure system settings, etc.
cd ~ || exit

tar -xzvf flannel.tar.gz 
cd flannel

sudo docker load < flannel-cni-plugin-v1.4.1-flannel1.tar
sudo docker load < flannel-v0.25.2.tar
cd

tar -xzvf nginx.tar.gz -C .
cd nginx || exit
# unpack and load images
for x in *.tar; do
    sudo docker load < "$x" && echo "Loaded from file $x"
done
check_error

sudo swapoff -a
setenforce 0
sudo touch /etc/selinux/config

sudo bash -c 'cat <<EOF >  /etc/selinux/config
SELINUX=permissive
EOF'

sudo bash -c 'cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF'

sudo sysctl --system
sudo systemctl enable kubelet.service

#kubectl version

cat <<EOF >  /home/ubuntu/kubeadm-config.yaml
# kubeadm-config.yaml
kind: ClusterConfiguration
apiVersion: kubeadm.k8s.io/v1beta3
kubernetesVersion: v1.29.5
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd   # <--- driver
EOF

ENDSSH

echo "Setup completed successfully."


ssh -i "$KEY_FILE" ubuntu@"$OFFLINE_SERVER_IP