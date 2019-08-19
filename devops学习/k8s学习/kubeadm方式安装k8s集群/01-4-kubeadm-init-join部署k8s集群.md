# 使用kubeadm方式部署k8s集群

---

## 在master节点上执行kubeadm init

### 概述
- 使用 kubeadm init --help 查看帮助信息
- kubeadm init 分为几个阶段 ，通过帮助信息进行详细查看
- 可以通过 kubeadm init phase 命令分阶段执行
- 重要参数
  - --apiserver-advertise-address   apiserver监听的地址
  - --ignore-preflight-errors   忽略某些报错
  - --image-repository   从哪个仓库去下载需要的镜像，默认是k8s.gcr.io---访问不到，使用阿里或者微软的私有仓库
  - --kubernetes-version  指定使用的版本
  - --pod-network-cidr   pod网络  参考格式为 10.244.0.0/16,根据实际可能的pod数量来设置网络范围--不同子网能容纳的数量不一样
  - --service-cidr       service网络 参考格式为 10.96.0.0/12
  - --dry-run            不真正执行命令，只输出将要执行的东西---这个命令非常重要，加上 -o  yaml 可以输出当前命令生成的yaml格式的内容，可以重定向到文件，修改之后，用apply -f 执行

### 执行 kubeadm init  (master节点)

``` bash
  kubeadm init --kubernetes-version=v1.15.1 \           #指定版本
   --pod-network-cidr=10.0.0.0/8 \                   #指定pod使用的网段
   --service-cidr=10.96.0.0/12 \                        #指定service使用的网段
   --ignore-preflight-errors=Swap \                     #忽略swap错误
  --image-repository registry.aliyuncs.com/google_containers     #指定从阿里云仓库下载
 
 # kubeadm init --kubernetes-version=v1.15.1 --pod-network-cidr=10.0.0.0/8 --service-cidr=10.96.0.0/12 --image-repository=registry.aliyuncs.com/google_containers

 # 执行完成后，可以通过[检查状态](#检查状态以及一些常用命令) 来查看状态
 # 执行成功后，会打印出一些信息，包括，拷贝kubeconfig文件--即kubectl默认使用的认证文件； kubeadm join 信息，注意拷贝，保存

```
``` bash
  #执行结果参考
[root@localhost ~]# kubeadm init --kubernetes-version=v1.15.1 --pod-network-cidr=10.0.0.0/8 --service-cidr=10.96.0.0/12 --image-repository=registry.aliyuncs.com/google_containers
[init] Using Kubernetes version: v1.15.1
[preflight] Running pre-flight checks
  [WARNING IsDockerSystemdCheck]: detected "cgroupfs" as the Docker cgroup driver. The recommended driver is "systemd". Please follow the guide at https://kubernetes.io/docs/setup/cri/
    [WARNING SystemVerification]: this Docker version is not on the list of validated versions: 19.03.1. Latest validated version: 18.09
    [preflight] Pulling images required for setting up a Kubernetes cluster
    [preflight] This might take a minute or two, depending on the speed of your internet connection
    [preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
    [kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
    [kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
    [kubelet-start] Activating the kubelet service
    [certs] Using certificateDir folder "/etc/kubernetes/pki"
    [certs] Generating "ca" certificate and key
    [certs] Generating "apiserver" certificate and key
    [certs] apiserver serving cert is signed for DNS names [localhost.localdomain kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.96.0.1 192.168.36.109]
    [certs] Generating "apiserver-kubelet-client" certificate and key
    [certs] Generating "etcd/ca" certificate and key
    [certs] Generating "etcd/server" certificate and key
    [certs] etcd/server serving cert is signed for DNS names [localhost.localdomain localhost] and IPs [192.168.36.109 127.0.0.1 ::1]
    [certs] Generating "etcd/peer" certificate and key
    [certs] etcd/peer serving cert is signed for DNS names [localhost.localdomain localhost] and IPs [192.168.36.109 127.0.0.1 ::1]
    [certs] Generating "etcd/healthcheck-client" certificate and key
    [certs] Generating "apiserver-etcd-client" certificate and key
    [certs] Generating "front-proxy-ca" certificate and key
    [certs] Generating "front-proxy-client" certificate and key
    [certs] Generating "sa" key and public key
    [kubeconfig] Using kubeconfig folder "/etc/kubernetes"
    [kubeconfig] Writing "admin.conf" kubeconfig file
    [kubeconfig] Writing "kubelet.conf" kubeconfig file
    [kubeconfig] Writing "controller-manager.conf" kubeconfig file
    [kubeconfig] Writing "scheduler.conf" kubeconfig file
    [control-plane] Using manifest folder "/etc/kubernetes/manifests"
    [control-plane] Creating static Pod manifest for "kube-apiserver"
    [control-plane] Creating static Pod manifest for "kube-controller-manager"
    [control-plane] Creating static Pod manifest for "kube-scheduler"
    [etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
    [wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
    [kubelet-check] Initial timeout of 40s passed.
    [apiclient] All control plane components are healthy after 40.505533 seconds
    [upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
    [kubelet] Creating a ConfigMap "kubelet-config-1.15" in namespace kube-system with the configuration for the kubelets in the cluster
    [upload-certs] Skipping phase. Please see --upload-certs
    [mark-control-plane] Marking the node localhost.localdomain as control-plane by adding the label "node-role.kubernetes.io/master=''"
    [mark-control-plane] Marking the node localhost.localdomain as control-plane by adding the taints [node-role.kubernetes.io/master:NoSchedule]
    [bootstrap-token] Using token: q42m82.2avd3k7uf2r3x6d3
    [bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
    [bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
    [bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
    [bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
    [bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
    [addons] Applied essential addon: CoreDNS
    [addons] Applied essential addon: kube-proxy

    Your Kubernetes control-plane has initialized successfully!

    To start using your cluster, you need to run the following as a regular user:

      mkdir -p $HOME/.kube
        sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
          sudo chown $(id -u):$(id -g) $HOME/.kube/config

          You should now deploy a pod network to the cluster.
          Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
            https://kubernetes.io/docs/concepts/cluster-administration/addons/

            Then you can join any number of worker nodes by running the following on each as root:

            kubeadm join 192.168.36.109:6443 --token q42m82.2avd3k7uf2r3x6d3 \
                --discovery-token-ca-cert-hash sha256:ae41fb39837a7ee8f806f51ac6688c2207a9afc2555c63188aed288839ac7777 

```                

### 为kubectl配置默认kubeconfig

``` bash
  # k8s建议用一个普通用户来配置kubectl认证信息，这里为了省事，直接用了root
  mkdir $HOME/.kube
  cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  chown $(id -u):$(id -g) $HOME/.kube/config
  # 执行完这些后，kubectl命令才能正常使用
  # 实际上，kubectl可以安装到任意一台能访问到apiserver的电脑上，包括windows，使用参数 --kubeconfig= 指定使用的认证文件---后边会专门描述这个认证文件
```


### 执行 kubeadm join (node节点)

``` bash
  kubeadm join 192.168.36.109:6443 --token q42m82.2avd3k7uf2r3x6d3 \
  105                 --discovery-token-ca-cert-hash sha256:ae41fb39837a7ee8f806f51ac6688c2207a9afc2555    c63188aed288839ac7777
```


### 检查状态以及一些常用命令

``` bash
  docker images   #查看下当前节点上有哪些镜像，应该能看到k8s主要组件的镜像
  kubectl get --help
  kubectl get nodes  #查看节点状态
  kubectl get cs
  kubectl get pods -n kube-system   # -n 是指定名称空间，k8s主要组件全在这个名称空间里
  kubectl describe xx  #查看某个资源的详细信息
  kubectl explain  xx  #查看某个资源的用法---有点像man帮助，非常详细，也非常重要

```
