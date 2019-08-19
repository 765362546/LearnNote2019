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
 
 # kubeadm init --kubernetes-version=v1.15.1 --pod-network-cidr=10.0.0.0/8 --service-cidr=10.96.0.0/12 --image-repository=192.168.36.108/google_containers

 # 执行完成后，可以通过[检查状态](#检查状态以及一些常用命令) 来查看状态
 # 执行成功后，会打印出 kubeadm join 信息，注意拷贝，保存

```

### 执行 kubeadm join (node节点)

``` bash
  
```


### 检查状态以及一些常用命令

``` bash
  kubectl get --help
  kubectl get nodes  #查看节点状态
  kubectl get cs
  kubectl get pods -n kube-system   # -n 是指定名称空间，k8s主要组件全在这个名称空间里
  kubectl describe xx  #查看某个资源的详细信息
  kubectl explain  xx  #查看某个资源的用法---有点像man帮助，非常详细，也非常重要
  docker images   #查看下当前节点上有哪些镜像，应该能看到k8s主要组件的镜像

```
