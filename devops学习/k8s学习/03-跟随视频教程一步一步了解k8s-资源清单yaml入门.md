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

``` 