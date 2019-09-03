# 跟随马哥视频教程一步一步了解k8s

---------

**知识点：下面全是（-_-）**

## 资源、对象

- workload: 工作负载型,运行应用程序，对外提供服务的，Pod 以及各种 pod 控制器 replicaSet、Deployment、StatefulSet、DaemonSet、Job、Cronjob...
- 服务发现及服务均衡：Service、Ingress... 说白就是对pod服务做代理的
- 配置与存储： 各种存储卷以及通过CSI容器存储接口实现的第三方存储
  - ConfigMap,Secret 经常用到的两个
  - DownwardAPI
  - ...
  
- 集群级别的资源
  - namespace(名称空间),Node,Role,ClusterRole,RoleBinding,ClusterRoleBinding  ***注，后边这些虽然不算是集群级别的，但是也是用来做集群管理，暂时放到这里***

- 元数据型资源
  - HPA 自动扩缩容、Podtemplate、LimitRange...

## 资源清单
  - apiserver仅接收json格式的资源定义，无论使用命令方式还是资源清单方式，都会转换成json格式，传给apiserver
  - yaml格式提供的资源清单，比较便于阅读  ***下面不区分的使用 属性和字段***
  - yaml语法不在这里深入，简单整理几条
    - 主要格式就是key: value 注意冒号后边必须有空格
    - 写子属性的时候，注意缩进----也可以直接来个大括号，放到父字段后边比如 lebels: {aa:xx,bb:yy}  等价于换行写子属性
    - 理解的时候，可以将整个yaml当做一个大的json来里面，一级字段，以及字段嵌套
  - **kubectl get 资源类型 名称 -o yaml  可以查看这个资源的yaml格式定义，比如 kubectl get pod myapp-84cd4b7f95-9t2fm -o yaml 其中 status是当前状态**
  - 大部分资源的配置清单，都有 5 个一级字段组成
    - apiVersion 要创建的资源，属于哪个群组，以及版本
      - kubectl api-versions 命令，可以显示apiserver包含的资源组和版本，同一个组可能有多个版本
      >> 其实用restful风格来理解就比较容易了，不同的组就类似不同的接口，加上版本号，就是同一个接口可能有不同的版本，即功能细节和参数上可能有些不同；通过json格式的报文，进行增删改查
  
    - kind 资源类别，打算创建什么类别的资源，比如Pod、Deployment
      - **kubectl api-resources 命令，可以显示支持的资源类别，以及它们点简称**
      - **kubectl explain 资源类别  命令，可以查看该资源具有哪些属性，怎么定义该资源清单；并且可以查看 资源类别.子属性 的定义，以及是否是必须的 **
    - metadata 元数据
      - name 同一类别、同一名称空间中必须唯一
      - namespace 名称空间
      - labels 标签
      - annotations 注解
      - selfLink 查看已有资源的yaml格式时，可以看到这个字段，显示的是这个资源对应apiserver的url地址
        - **补充知识点：资源的引用路径 /api/资源组/资源版本/namespace/表空间名/资源类别/资源具体名称 ；比如 /api/v1/namespaces/default/pods/myapp-84cd4b7f95-9t2fm 注意核心组就叫v1**
        - **补充知识点：资源的引用路径，可以直接通过 https://apiserver:port/资源引用路径访问，前提是apiserver地址允许被访问，默认直接访问apiserver，需要ca证书的**
        - **补充知识点：资源的引用路径，在执行kubectl proxy之后，可以使用 proxy 之后的地址，通过http协议访问，不用验证ca证书**
        - **补充知识点：资源的引用路径，可以用 kubectl get --raw="资源引用路径" 直接访问，返回json格式的报文，可以加上|jq 对结果格式化**
    - spec
      - 用来定义**期望的状态**
      - Specification，英文解释是规格、详述、说明书，这个字段**非常重要**
      - 根据资源类别不同，具有不同的子属性；
    - status  
      - 使用kubectl get xx -o yaml时，可以看到改字段，表示**当前状态**
      - 由k8s集群维护该字段，并且会让资源朝着spec定义的**期望的状态**靠拢，用户不能手动定义
      
  - **强调： kubectl explain 资源类别  命令，可以查看该资源具有哪些字段，怎么定义该资源清单；并且可以查看 资源类别.子属性 的定义，以及是否是必须的 **
  
## 试验

### 创建一个pod-demo.yaml
  
- 用kubectl explain pods 查看，注意里面用#添加的注释信息，帮助理解
```bash
[root@master ~]# kubectl explain pod
KIND:     Pod  #列出来类别
VERSION:  v1   #列出了apiVersion 资源组/版本

DESCRIPTION:   #描述信息
     Pod is a collection of containers that can run on a host. This resource is
     created by clients and scheduled onto hosts.

FIELDS:        #字段 
   apiVersion   <string>   #字段名称 以及 类型，string，字符串
     APIVersion defines the versioned schema of this representation of an
     object. Servers should convert recognized schemas to the latest internal
     value, and may reject unrecognized values. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#resources

   kind <string>
     Kind is a string value representing the REST resource this object
     represents. Servers may infer this from the endpoint the client submits
     requests to. Cannot be updated. In CamelCase. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#types-kinds

   metadata     <Object> # 类型是个对象，也就是键值对，可以用kubectl explain pod.metadata 继续查看
     Standard object's metadata. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#metadata

   spec <Object>
     Specification of the desired behavior of the pod. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#spec-and-status

   status       <Object>
     Most recently observed status of the pod. This data may not be up to date.
     Populated by the system. Read-only. More info:
     https://git.k8s.io/community/contributors/devel/api-conventions.md#spec-and-status

```

- 根据上面查询到的信息，写yaml，注意，严格区分大小写
```bash
[root@master test]# vim pod-demo.yaml
apiVersion: v1   #上面查询到的pod的api版本信息
kind: Pod        #上面查询到的资源类别，注意大小写
metadata:        #类型为对象，需要继续查询
spec:            #同上
```

- 用kubectl explain pods.metadata 查看metadata字段的说明  只列出几个主要的
```bash
[root@master test]# kubectl explain pods.metadata
KIND:     Pod
VERSION:  v1

RESOURCE: metadata <Object>
FIELDS:
  name: pod名称，在同一个名称空间里，必须唯一
  namespace: 该pod在哪个名称空间里创建 默认default
  labels <map[string]string>: 标签，可以给这个pod打多个标签，其他东西引用资源时，可以通过标签选择器来选择，类型是对象数组，就是一个json，里面有多个键值对
```

- 继续完善pod-demo.yaml
```bash
[root@master test]# vim pod-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:         #这三行，等价于 labels: {app: myapp,tier: fronted}
    app: myapp    #标签的内容，根据需要来定，不是固定的
    tier: fronted
spec:          
```

- 用kubectl explain pods.spec 查看spec字段的说名---不同类别的spec内容不一样
```bash
[root@master test]# kubectl explain pods.spec
KIND:     Pod
VERSION:  v1

RESOURCE: spec <Object>
FIELDS:
  containers   <[]Object> -required-  
  #标着required表示必须； 
  #containers类型是数组，组成数组的内容是对象，用json表示就是[{aa:xx,bb:yy},{cc:zz}]
  #yaml数组，注意语法
#用explain继续查看containers说明
kubectl explain pods.spec.containers
 name <string> -required-  #容器名称
 image:                    #使用的镜像
 imagePullPolicy           #拉取镜像的策略，包括Always, Never, IfNotPresent三种
 command                   # 容器中执行的cmd，格式是数组
 ... #其他的用到在进行说明
````

- 继续完善pod-demo.yaml
```bash
[root@master test]# vim pod-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: pod-demo
  namespace: default
  labels:
    app: myapp
    tier: fronted
spec:
  containers:
    - name: myapp-web
      image: nginx:1.17.3-alpine
    - name: myapp-client
      image: busybox:latest
      command:
        - "/bin/sh"
        - "-c"
        - "sleep 3600"
        
 # 最后四行，等价于 command: ["/bin/sh","-c","sleep 3600"]       

``` 

- 通过资源清单创建资源 命令 kubectl create -f FILENAME [options]  (后边说说明apply命令)
```bash
[root@master test]# kubectl create -f pod-demo.yaml  #通过create命令创建资源
pod/pod-demo created
[root@master test]# kubectl get pods                 #查看判断，可以看到pod-demo包含两个容器，并且状态都是已运行
NAME       READY   STATUS    RESTARTS   AGE
pod-demo   2/2     Running   0          7s
[root@master test]# kubectl describe pod pod-demo    #通过describe命令，查看pod的详细信息
Name:         pod-demo                               #pod名称 
Namespace:    default                                #pod所在的名称空间
Priority:     0
Node:         node3/192.168.36.107                   #pod所在的节点
Start Time:   Tue, 03 Sep 2019 14:29:25 +0800
Labels:       app=myapp                              #pod包含的标签
              tier=fronted
Annotations:  cni.projectcalico.org/podIP: 10.0.3.15/32 #pod网络相关，可以看出，下面的两个容器，共用一个ip
Status:       Running
IP:           10.0.3.15
Containers:                                           #分别列出两个容器的信息
  myapp-web:
    Container ID:   docker://5188a5f2a2a9ffcd3fecfae904d01c5a11425632db780d6365be6baac334d199
    Image:          nginx:1.17.3-alpine
    Image ID:       docker-pullable://nginx@sha256:b9c2c032a6f282c914a8c8fab52994b4ad7940794971fe9766fb7b2ca8da8868
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Tue, 03 Sep 2019 14:29:27 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-b622t (ro)
  myapp-client:
    Container ID:  docker://9fce33d7445c5be36d1e72a201846afa47444e573c49182433a4d9aef226e2a0
    Image:         busybox:latest
    Image ID:      docker-pullable://busybox@sha256:9f1003c480699be56815db0f8146ad2e22efea85129b5b5983d0e0fb52d9ab70
    Port:          <none>
    Host Port:     <none>
    Command:
      /bin/sh
      -c
      sleep 3600
    State:          Running
      Started:      Tue, 03 Sep 2019 14:29:29 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from default-token-b622t (ro)
Conditions:
  Type              Status
  Initialized       True
  Ready             True
  ContainersReady   True
  PodScheduled      True
Volumes:
  default-token-b622t:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-b622t
    Optional:    false
QoS Class:       BestEffort
Node-Selectors:  <none>
Tolerations:     node.kubernetes.io/not-ready:NoExecute for 300s
                 node.kubernetes.io/unreachable:NoExecute for 300s
Events:                                                       # 列出pod运行的事件，下面详细解释
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  79s   default-scheduler  Successfully assigned default/pod-demo to node3   #调度到node3
  Normal  Pulled     79s   kubelet, node3     Container image "nginx:1.17.3-alpine" already present on machine  #根据默认的镜像拉取策略，发现已存在这个镜像
  Normal  Created    79s   kubelet, node3     Created container myapp-web       #创建容器
  Normal  Started    78s   kubelet, node3     Started container myapp-web       #启动容器
  Normal  Pulling    78s   kubelet, node3     Pulling image "busybox:latest"    #根据默认的镜像拉取策略，拉取busybox镜像
  Normal  Pulled     77s   kubelet, node3     Successfully pulled image "busybox:latest"  #镜像拉取成功
  Normal  Created    77s   kubelet, node3     Created container myapp-client      #创建容器
  Normal  Started    76s   kubelet, node3     Started container myapp-client      #启动容器

[root@master test]# curl 10.0.3.15     #上面创建的pod提供了nginx服务，通过pod地址访问一下
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
...

```

- 通过logs命令查看容器日志
```bash
[root@master test]#  kubectl logs --help    
 kubectl logs [-f] [-p] (POD | TYPE/NAME) [-c CONTAINER] [options]  #根据pod内容器的数量不通，部分参数可以省略
 
[root@master test]# kubectl logs pod-demo myapp-web   # 通过logs命令，查看容器的日志
192.168.36.107 - - [03/Sep/2019:06:36:22 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.29.0" "-"
```

- 通过exec命令在容器中执行命令 kubectl exec (POD | TYPE/NAME) [-c CONTAINER] [flags] -- COMMAND [args...] [options]
```bash
#最常用的就是进入到容器的shell中，然后在执行其他命令
[root@master test]# kubectl exec pod-demo -c myapp-client  -it -- /bin/sh
/ #
#然后就可以在容器中执行命令
```

- 通过资源清单删除资源  命令 kubectl delete ([-f FILENAME] | [-k DIRECTORY] | TYPE [(NAME | -l label | --all)]) [options]
```bash
[root@master test]# kubectl delete -f pod-demo.yaml
pod "pod-demo" deleted
#通过kubectl get pods 命令可以查看到pod已经没了
#kubectl delete 也可以删除其他资源
```

- 通过apply命令创建资源
  - 声明式创建资源，与create不同的是，apply会比较要创建的资源与现有资源，如果不存在，就创建，此时跟create没区别，如果存在，会将已有资源升级到新的资源清单里描述的内容
  - 我的理解，能用apply的就用apply

- 通过edit命令修改资源  kubectl edit (RESOURCE/NAME | -f FILENAME) [options]
  - 类似于打开一个vim界面，直接编辑内容，编辑之后，会立即生效----部分资源不支持这种方式

## 整理

  - 资源清单格式
    - 一级字段： apiVersion(group/version),kind,metadata(name,namespace,labels,annotations,...),spec,status(只读)
  - Pod资源
    - pods.spec.containers <[]Object>  
      - 数组，可以包含多个容器
      - imagePullPolicy: Always 总是下载,;Never 从不下载;IfNotPresent 没有就下载
      - 默认值，如果镜像版本(tag)是latest，默认值是Always;否则，默认值是IfNotPresent
      - 在资源清单里设置这个之后，就不按照默认值了;比如设置为IfNotPresent之后，即使tag是latest，如果已存在镜像，也不会去拉取了
      - ports <[]Object> 对象列表，可以多个 这里仅仅是给出信息，并不能控制容器暴露或者不暴露端口；配置上这一项，可以在别的地方直接引用它的名称

    