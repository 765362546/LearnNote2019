# 跟随马哥视频教程一步一步了解k8s

---------

** 知识点：下面全是（-_-）**

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
  - yaml格式提供的资源清单，比较便于阅读
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
      
    
  
  