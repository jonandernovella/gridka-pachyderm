# Update package list
sudo apt-get update

# Dependencies
sudo apt-get install socat
sudo apt-get install unzip
curl -LC - -o /tmp/libltdl7.deb http://se.archive.ubuntu.com/ubuntu/pool/main/libt/libtool/libltdl7_2.4.6-0.1_amd64.deb
sudo dpkg -i /tmp/libltdl7.deb

# Docker installation
curl -LC - -o /tmp/docker.deb https://download.docker.com/linux/ubuntu/dists/xenial/pool/stable/amd64/docker-ce_17.03.2~ce-0~ubuntu-xenial_amd64.deb
sudo dpkg -i /tmp/docker.deb

# Install kubectl
curl -LC - -o /tmp/kubectl https://storage.googleapis.com/kubernetes-release/release/v1.11.0/bin/linux/amd64/kubectl
sudo chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin/kubectl

# Minikube installation
curl -LC - -o /tmp/minikube https://storage.googleapis.com/minikube/releases/v0.28.2/minikube-linux-amd64
chmod +x /tmp/minikube
sudo mv /tmp/minikube /usr/local/bin/minikube

# Install Helm
curl -LC - -o /tmp/helm.tar.gz https://storage.googleapis.com/kubernetes-helm/helm-v2.9.1-linux-amd64.tar.gz
tar -zxvf /tmp/helm.tar.gz -C /tmp
sudo mv /tmp/linux-amd64/helm /usr/local/bin/helm

# Install pachctl
curl -LC - -o /tmp/pachctl.deb https://github.com/pachyderm/pachyderm/releases/download/v1.7.3/pachctl_1.7.3_amd64.deb
sudo dpkg -i /tmp/pachctl.deb

# Start minikube
# sudo minikube start --vm-driver=none
# Start Helm client and daemon
# sudo helm init
# Start Pachyderm daemon
# sudo helm install --namespace pachyderm --name my-release stable/pachyderm