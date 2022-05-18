cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sudo sysctl --system

sudo yum install -y yum-utils

sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo


sudo yum install containerd.io -y

cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF

sudo sysctl --system

sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml

sudo systemctl restart containerd

#edit /etc/containerd/config.toml
#
#[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
#  ...
#  [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
#    SystemdCgroup = true

sudo systemctl restart containerd
sudo systemctl enable containerd



cat <<EOF | sudo tee /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
exclude=kubelet kubeadm kubectl
EOF

sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

sudo yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes

sudo systemctl enable --now kubelet




gcloud compute instances create etcd-1 --source-instance-template etcd --zone us-central1-a --async
gcloud compute instances create etcd-2 --source-instance-template etcd --zone us-central1-c --async
gcloud compute instances create etcd-3 --source-instance-template etcd --zone us-central1-f --async

sudo mkdir -p /etc/systemd/system/kubelet.service.d/

cat << EOF | sudo tee /etc/systemd/system/kubelet.service.d/20-etcd-service-manager.conf
[Service]
ExecStart=
#  Replace "systemd" with the cgroup driver of your container runtime. The default value in the kubelet is "cgroupfs".
ExecStart=/usr/bin/kubelet --address=0.0.0.0 --pod-manifest-path=/etc/kubernetes/manifests --cgroup-driver=systemd --container-runtime-endpoint=unix:///run/containerd/containerd.sock
Restart=always
EOF

sudo systemctl daemon-reload

sudo systemctl restart kubelet
sudo systemctl status kubelet


export HOST0=10.1.4.2
export HOST1=10.1.4.3
export HOST2=10.1.4.4

mkdir -p /tmp/${HOST0}/ /tmp/${HOST1}/ /tmp/${HOST2}/

ETCDHOSTS=(${HOST0} ${HOST1} ${HOST2})
NAMES=("rvloona-etcd-0" "rvloona-etcd-1" "rvloona-etcd-2")

for i in "${!ETCDHOSTS[@]}"; do
HOST=${ETCDHOSTS[$i]}
NAME=${NAMES[$i]}
cat << EOF > /tmp/${HOST}/kubeadmcfg.yaml
apiVersion: "kubeadm.k8s.io/v1beta3"
kind: ClusterConfiguration
etcd:
    local:
        serverCertSANs:
        - "${HOST}"
        - "etcd.rvloona.com"
        - "10.1.2.2"
        peerCertSANs:
        - "${HOST}"
        extraArgs:
            initial-cluster: ${NAMES[0]}=https://${ETCDHOSTS[0]}:2380,${NAMES[1]}=https://${ETCDHOSTS[1]}:2380,${NAMES[2]}=https://${ETCDHOSTS[2]}:2380
            initial-cluster-state: new
            name: ${NAME}
            listen-peer-urls: https://${HOST}:2380
            listen-client-urls: https://${HOST}:2379
            advertise-client-urls: https://${HOST}:2379
            initial-advertise-peer-urls: https://${HOST}:2380
            listen-metrics-urls: http://${HOST}:2381, http://127.0.0.1:2381
EOF
done

sudo kubeadm init phase certs etcd-ca

sudo kubeadm init phase certs etcd-server --config=/tmp/${HOST2}/kubeadmcfg.yaml
sudo kubeadm init phase certs etcd-peer --config=/tmp/${HOST2}/kubeadmcfg.yaml
sudo kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
sudo kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST2}/kubeadmcfg.yaml
sudo cp -R /etc/kubernetes/pki /tmp/${HOST2}/
sudo find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

sudo kubeadm init phase certs etcd-server --config=/tmp/${HOST1}/kubeadmcfg.yaml
sudo kubeadm init phase certs etcd-peer --config=/tmp/${HOST1}/kubeadmcfg.yaml
sudo kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
sudo kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST1}/kubeadmcfg.yaml
sudo cp -R /etc/kubernetes/pki /tmp/${HOST1}/
sudo find /etc/kubernetes/pki -not -name ca.crt -not -name ca.key -type f -delete

sudo kubeadm init phase certs etcd-server --config=/tmp/${HOST0}/kubeadmcfg.yaml
sudo kubeadm init phase certs etcd-peer --config=/tmp/${HOST0}/kubeadmcfg.yaml
sudo kubeadm init phase certs etcd-healthcheck-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
sudo kubeadm init phase certs apiserver-etcd-client --config=/tmp/${HOST0}/kubeadmcfg.yaml
# No need to move the certs because they are for HOST0

# clean up certs that should not be copied off this host
sudo find /tmp/${HOST2} -name ca.key -type f -delete
sudo find /tmp/${HOST1} -name ca.key -type f -delete

ssh-keygen -t ed25519

sudo chown -R fernando:fernando /tmp/10.1.4*

scp -r /tmp/10.1.4.3/* etcd-1:
scp -r /tmp/10.1.4.4/* etcd-2:

sudo -Es
chown -R root:root pki
mv pki /etc/kubernetes/
exit

mkdir -p /tmp/10.1.4.3/
mv kubeadmcfg.yaml /tmp/10.1.4.3/

sudo -Es
chown -R root:root pki
mv pki /etc/kubernetes/
exit

mkdir -p /tmp/10.1.4.4/
mv kubeadmcfg.yaml /tmp/10.1.4.4/


sudo kubeadm init phase etcd local --config=/tmp/10.1.4.2/kubeadmcfg.yaml
sudo kubeadm init phase etcd local --config=/tmp/10.1.4.3/kubeadmcfg.yaml
sudo kubeadm init phase etcd local --config=/tmp/10.1.4.4/kubeadmcfg.yaml