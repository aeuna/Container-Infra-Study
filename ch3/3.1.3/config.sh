# 쿠버네티스 설치하기 위한 사전 조건을 설정하는 스크립트 파일. 쿠버네티스의 노드가 되는 가상 머신에 어떤 값을 설정하는지
#!/usr/bin/env bash

# vi를 호출하면 vim을 호출하도록 프로파일에 입력 
echo 'alias vi=vim' >> /etc/profile

# 쿠버네티스의 설치 요구 조건을 맞추기 위해 스왑되지 않도록 설정 
swapoff -a
# 시스템이 다시 시작되더라도 스왑되지 않도록 설정
sed -i.bak -r 's/(.+ swap .+)/#\1/' /etc/fstab

# 쿠버네티스의 리포지터리를 설정하기 위한 경로 변수 처리
gg_pkg="packages.cloud.google.com/yum/doc" # Due to shorten addr for key
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=0
repo_gpgcheck=0
gpgkey=https://${gg_pkg}/yum-key.gpg https://${gg_pkg}/rpm-package-key.gpg
EOF

# selinux가 제한되지 않도록 permissive 모드 변경
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# 파드의 통신을 iptables로 제어. br_netfilter 적용함으로써 iptables 활성화
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
modprobe br_netfilter

# 노드 간 통신을 이름으로 할 수 있도록 각 노드의 호스트 이름과 IP를 /etc/hosts 에 설정한다.
echo "192.168.1.10 m-k8s" >> /etc/hosts
for (( i=1; i<=$1; i++  )); do echo "192.168.1.10$i w$i-k8s" >> /etc/hosts; done

# DNS 서버 지정  
cat <<EOF > /etc/resolv.conf
nameserver 1.1.1.1 #cloudflare DNS
nameserver 8.8.8.8 #Google DNS
EOF

