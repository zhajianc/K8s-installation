# K8s-installation
1. Create VM

1.1 Create PV/VG/LV....

lvcreate -L1.5T --thinpool /dev/DomU/wade_thinpool /dev/DomU

for node in slc09jg{u..x} slc09jgz
do
lvcreate -n $node --thin -V500G /dev/DomU/wade_thinpool
done

1.2 copy OS image

for node in slc09jg{u..x} slc09jgz
do
dd if=/vmstate/new.img of=/dev/DomU/$node bs=2M &
done

1.3 Build the VM

umount -l /mnt

for node in slc09jgz slc09jg{u..x}
do

losetup -f /dev/DomU/$node
kpartx -av /dev/loop0
lvchange -f -ay centos/root
mount /dev/centos/root /mnt

fqdn=$node.us.oracle.com
ip=`dig +short $fqdn`
gw=`ip route  |grep default |awk '{print $3}'`

sed -i "s/^.*$/$node/" /mnt/etc/hostname

sed -i "s/^10.*$/$ip\t\t$fqdn\t$node/" /mnt/etc/hosts

sed -i "s/^GATEWAY=.*$/GATEWAY=$gw/" /mnt/etc/sysconfig/network

sed -i "s/^IPADDR=.*$/IPADDR=$ip/" /mnt/etc/sysconfig/network-scripts/ifcfg-eth0

sed -i "s/^myhostname=.*$/myhostname=$fqdn/" /mnt/etc/postfix/main.cf

sed -i "s/^mydomain=.*$/mydomain=$fqdn/" /mnt/etc/postfix/main.cf


cat /mnt/etc/hostname

cat /mnt/etc/hosts |grep slc

cat /mnt/etc/sysconfig/network |grep GATE

cat /mnt/etc/sysconfig/network-scripts/ifcfg-eth0 |grep IPADDR

egrep "^myhostname|^mydomain" /mnt/etc/postfix/main.cf


umount -l /mnt

lvchange -an centos/root

sleep 2

kpartx -d /dev/loop0

losetup -d /dev/loop0

virsh create /etc/libvirt/qemu/$node.xml


done

1.4 Copy ssh key from ansible server

for node in slc09jg{u..x} slc09jgz
do
ssh-copy-id -i /root/.ssh/id_rsa.pub root@$node
done 

1.5 Use ansible to configure the VMs


ansible k8s -m shell -a "parted /dev/xvda resizepart 2 100%"
ansible k8s -m shell -a "pvresize /dev/xvda2"
ansible k8s -m lvol -a "vg=centos lv=root resizefs=yes size=20G"
ansible k8s -m lvol -a "vg=centos lv=opt state=present size=400G"
ansible k8s -m filesystem -a "dev=/dev/centos/opt fstype=xfs"
ansible k8s -m lineinfile -a 'path=/etc/fstab state=present backup=yes backup=true line="/dev/mapper/centos-opt         /opt      xfs    defaults                    0 0" regexp="^/dev/mapper/centos-opt"'
ansible k8s -m reboot
ansible k8s -m shell -a "mv /root/cni /opt"
ansible k8s -m shell -a "shutdown now"

1.6 Create snapshot
for node in slc09jg{u..x} slc09jgz
do
lvrename /dev/DomU/$node /dev/DomU/$node.orig
lvcreate -n $node -s /dev/DomU/$node.orig
lvchange -ay -K /dev/DomU/$node
virsh create /etc/libvirt/qemu/$node.xml
done

for node in slc09jg{u..x} slc09jgz
do
#virsh create /etc/libvirt/qemu/$node.xml
#lvconvert --merge DomU/$node
done

for node in slc09jg{u..x} slc09jgz
do
xm destroy $node
lvremove -f /dev/DomU/$node
lvcreate -n $node -s /dev/DomU/$node.orig
lvchange -ay -K /dev/DomU/$node
virsh create /etc/libvirt/qemu/$node.xml
done 

for node in slc09jgu
do
xm destroy $node
lvremove -f /dev/DomU/$node
lvcreate -n $node -s /dev/DomU/$node.orig
lvchange -ay -K /dev/DomU/$node
virsh create /etc/libvirt/qemu/$node.xml
done 


2. Install kubernetes

2.1 Build master/minion

kubeadm init --pod-network-cidr=172.23.0.0/16 -v 1000 --service-cidr=172.24.0.0/16 -v 5

ansible k8s-node -m shell -a "kubeadm join 10.245.156.166:6443 --token v75ib0.1wgzvq66dmzku9lw \
    --discovery-token-ca-cert-hash sha256:5e1b3b261ae9d3143b5b31ea0e5116a4e38d53d54df26b9c99485b02a0ee3345"
    
ansible k8s -m lineinfile -a "path=/root/.bash_profile regexp='export KUBECONFIG*' line='export KUBECONFIG=/etc/kubernetes/admin.conf'"

2.2 Confige the CNI

export KUBECONFIG=/etc/kubernetes/admin.conf
wget https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/rbac-kdd.yaml
wget https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/kubernetes-datastore/calico-networking/1.7/calico.yaml


modify the yaml file to meet the real, pod-network-cidr setting

kubectl apply -f rbac-kdd.yaml

kubectl apply -f calico.yaml

2.3 Configure Ingress

wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml

kubectl apply -f mandatory.yaml

kubectl apply -f service-nodeport.yaml

Build the a service

2.4 Configure the dashboard
wget https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml

openssl genrsa -out /etc/kubernetes/pki/dashboard.key 2048
openssl req -new -out /etc/kubernetes/pki/dashboard.csr -key /etc/kubernetes/pki/dashboard.key -subj '/CN=slc09jgu.us.oracle.com'
openssl x509 -req -in /etc/kubernetes/pki/dashboard.csr -signkey /etc/kubernetes/pki/dashboard.key -out /etc/kubernetes/pki/dashboard.crt
openssl x509 -in /etc/kubernetes/pki/dashboard.crt -text -noout
kubectl -n kube-system create secret generic kubernetes-dashboard-certs --from-file=/etc/kubernetes/pki/dashboard.key --from-file=/etc/kubernetes/pki/dashboard.crt
vi kubernetes-dashboard.yaml
and add the nodePort/type into the yaml file(service  section)

kubectl apply -f kubernetes-dashboard.yaml

Create Token:
kubectl create serviceaccount dashboard-admin -n kube-system
kubectl get sa -n kube-system
kubectl create clusterrolebinding dashboard-cluster-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin
kubectl get secret -n kube-system

kubectl describe secret dashboard-admin-token-9xj4s -n kube-system


kubeconfig:
kubectl create serviceaccount def-ns-admin -n default
kubectl create rolebinding def-ns-admin --clusterrole=admin --serviceaccount=default:def-ns-admin
kubectl get secret
kubectl describe secret def-ns-admin-token-xdvx5

