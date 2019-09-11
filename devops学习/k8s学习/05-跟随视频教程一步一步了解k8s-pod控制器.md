# 跟随马哥视频教程一步一步了解k8s

**也全是知识点**

## pod控制器

- 常用的几种控制器
  - ReplicaSet: 
    - 代用户创建指定数量的pod副本数量，确保pod副本数量符合预期状态，并且支持滚动式自动扩容和缩容功能
    - 帮助用户管理无状态的pod资源，精确反应用户定义的目标数量，但是RelicaSet不是直接使用的控制器，而是使用Deployment
    - ReplicaSet主要三个组件组成： 用户期望的pod副本数量；标签选择器，判断哪个pod归自己管理;当现存的pod数量不足，会根据pod资源模板进行新建
  - Deployment(常用)：
    - 工作在ReplicaSet之上，用于管理无状态应用，目前来说最好的控制器。支持滚动更新和回滚功能，还提供声明式配置。
  - DaemonSet：用于确保集群中的每一个节点只运行特定的pod副本，通常用于实现系统级后台任务。比如ELK服务
    - 特性：服务是无状态的
    - 服务必须是守护进程
  - Job：只要完成就立即退出，不需要重启或重建
  - Cronjob：周期性任务控制，不需要持续后台运行
  - StatefulSet：管理有状态应用,比如数据库集群，主节点和从节点之间都是有状态的
  

## 试验--通过试验来理解控制器

### ReplicaSet试验
```bash
#ReplicaSet简称rs,通过explain查看语法
[root@master ~]# kubectl explain rs
apiVersion
kind
metadata
spec
status
#这几项与pod的类似，下面看下spec的语法
[root@master ~]# kubectl explain rs.spec
replicas  #副本数量
selector  #标签选择器---用哪些标签来选择pod
template  #pod模板---这个下面会嵌套pod的资源清单,pod的标签，必须包含上边定义的，要不然关联不上
#pod控制器会控制pod向清单定义的方向不断靠近，比如副本数量，多退少补
#如果创建的pod没法被控制器关联，控制器会不断创建pod----经验证，如果资源清单里定义的标签选择器和pod的标签匹配不上，创建的时候就会提示错误

#查看selector的语法
[root@master ~]# kubectl explain rs.spec.selector
matchExpressions
matchLabels
#两种匹配方式，这里先不具体展开
#查看template的语法
[root@master ~]# kubectl explain rs.spec.template
metadata
spec
#这里实际就是定义pod模板的资源清单，注意在metadata里添加labels

######
[root@master test]# vim rs-demo.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: rs-demo
  namespace: default
spec:
  replicas: 3
  selector:
    matchLabels:
      app: rs-demo
      release: canary
  template:
    metadata:
      labels:
        app: rs-demo
        release: canary
        environment: test
    spec:
      containers:
        - name: rs-demo-container
          image: ikubernetes/myapp:v1
          ports:
            - name: http
              containerPort: 80

[root@master test]# kubectl apply -f rs-demo.yaml
replicaset.apps/rs-demo created

[root@master test]# kubectl get rs
NAME      DESIRED   CURRENT   READY   AGE
rs-demo   3         3         3       18s
[root@master test]# kubectl get pods -o wide
NAME            READY   STATUS    RESTARTS   AGE   IP          NODE    NOMINATED NODE   READINESS GATES
poststart-pod   1/1     Running   0          22h   10.0.3.27   node3   <none>           <none>
rs-demo-9gn96   1/1     Running   0          8s    10.0.1.20   node1   <none>           <none>
rs-demo-g4x7d   1/1     Running   0          8s    10.0.2.53   node2   <none>           <none>
rs-demo-z9qlf   1/1     Running   0          8s    10.0.3.28   node3   <none>           <none>
#pod名称是自动生成的，是控制器名称加随机数，即使在yaml里配置上pod名称也无效
#手动删除一个pod，控制器会再次创建，知道副本数达到资源清单中定义的数量
[root@master test]# kubectl delete pod rs-demo-z9qlf
pod "rs-demo-z9qlf" deleted

[root@master test]# kubectl get pods -o wide
NAME            READY   STATUS    RESTARTS   AGE     
poststart-pod   1/1     Running   0          22h     
rs-demo-4bvbq   1/1     Running   0          13s   #这个是新创建的  
rs-demo-9gn96   1/1     Running   0          2m50s   
rs-demo-g4x7d   1/1     Running   0          2m50s   

#如果给其他pod，添加labels，使之被控制器的标签选择权匹配，此时副本数量超过定义的，控制器会随机干掉一个----所以一定要定义好合适的标签和标签选择器
[root@master test]# kubectl label pod poststart-pod  app=rs-demo release=canary 
[root@master test]# kubectl get pods --show-labels
NAME            READY   STATUS        RESTARTS   AGE     LABELS
poststart-pod   1/1     Running       0          22h     app=rs-demo,release=canary
rs-demo-4bvbq   0/1     Terminating （这个被干掉了）  0          4m45s   app=rs-demo,environment=test,release=canary
rs-demo-9gn96   1/1     Running       0          7m22s   app=rs-demo,environment=test,release=canary
rs-demo-g4x7d   1/1     Running       0          7m22s   app=rs-demo,environment=test,release=canary
```

### Deployment试验
- Deployment控制ReplicaSet,ReplicaSet控制Pods----我的理解ReplicaSet是最原始的功能，Deployment是又封装了一层，并且加一些功能
- 更新策略
  - 当对pod进行更新时，实际上是重建pod，而不是更新pod的内容-----删掉，重建
  - 当更新时，是没有满足副本数量的，在加上一些对性能指标的要求，需要制定更新策略，比如，更新时，实际运行的副本数量比要求的副本数量可以多多少、可以少多少
  - 举例子，更新时，可以新建一个新的pod，然后删除一个旧的pod，也可以先删后建-----具体的策略，可以在资源清单里配置
  - 发布方式，参考 金丝雀、灰度、蓝绿发布 <https://www.cnblogs.com/apanly/p/8784096.html>
```bash
[root@master test]# kubectl explain deployment.spec.strategy
 type <string>  #如果类型是滚动升级，则下面那个字段生效，可以指定策略；如果是recreate，就是删一个，然后建一个
     Type of deployment. Can be "Recreate" or "RollingUpdate". Default is
     RollingUpdate.
 rollingUpdate        <Object>
     Rolling update config params. Present only if DeploymentStrategyType =
     RollingUpdate.
     
 [root@master test]# kubectl explain deployment.spec.strategy.rollingUpdate    
maxSurge  #最多能超出副本数量几个
maxUnavailable  #最多能少几个
#取值可以是数字，也可以是百分比，两个参数不能同时为0
```

```bash
#deployment示例
[root@master test]# vim deploy-demo.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: deploy-demo
  namespace: default
spec:
  replicas: 2
  selector:
    matchLabels:
      app: deploy-demo
      release: canary
  template:
    metadata:
      labels:
        app: deploy-demo
        release: canary
    spec:
      containers:
        - name: deploy-demo-pod
          image: ikubernetes/myapp:v1


[root@master test]# kubectl apply -f deploy-demo.yaml
deployment.apps/deploy-demo created
[root@master test]# kubectl get deployments.
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
deploy-demo   2/2     2            2           7s
[root@master test]# kubectl get rs  #可以看到自动创建了ReplicaSet---名称后边那一串，是清单模板的hash值，唯一的
NAME                     DESIRED   CURRENT   READY   AGE
deploy-demo-76d96b77bb   2         2         2       3m9s
[root@master test]# kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
deploy-demo-76d96b77bb-cs2jq   1/1     Running   0          11s
deploy-demo-76d96b77bb-dcbnt   1/1     Running   0          11s
poststart-pod                  1/1     Running   0          24h
rs-demo-9gn96                  1/1     Running   0          106m
rs-demo-g4x7d                  1/1     Running   0          106m
rs-demo-t6tnq                  1/1     Running   0          98m
rs-demo-wsxjm                  1/1     Running   0          92m

#更新，这次直接修改yaml，然后用apply执行
[root@master test]# vim deploy-demo.yaml
image: ikubernetes/myapp:v2   
# 修改镜像版本，然后应用
[root@master test]# kubectl apply -f deploy-demo.yaml

[root@master ~]# kubectl get pods -l app=deploy-demo -w  #通过-l 筛选pod，通过-w持续观察
NAME                           READY   STATUS    RESTARTS   AGE
deploy-demo-76d96b77bb-cs2jq   1/1     Running   0          34m
deploy-demo-76d96b77bb-dcbnt   1/1     Running   0          34m    #这是原有的两个
deploy-demo-8d4c45d5f-5r6bh    0/1     Pending   0          0s     #新建一个
deploy-demo-8d4c45d5f-5r6bh    0/1     Pending   0          0s
deploy-demo-8d4c45d5f-5r6bh    0/1     ContainerCreating   0          0s
deploy-demo-8d4c45d5f-5r6bh    0/1     ContainerCreating   0          1s
deploy-demo-8d4c45d5f-5r6bh    1/1     Running             0          2s #创建成功
deploy-demo-76d96b77bb-cs2jq   1/1     Terminating         0          35m #删一个
deploy-demo-8d4c45d5f-hqbl6    0/1     Pending             0          0s #在创建一个
deploy-demo-8d4c45d5f-hqbl6    0/1     Pending             0          0s
deploy-demo-8d4c45d5f-hqbl6    0/1     ContainerCreating   0          0s
deploy-demo-8d4c45d5f-hqbl6    0/1     ContainerCreating   0          2s
deploy-demo-76d96b77bb-cs2jq   0/1     Terminating         0          35m
deploy-demo-8d4c45d5f-hqbl6    1/1     Running             0          3s #创建成功 
deploy-demo-76d96b77bb-dcbnt   1/1     Terminating         0          35m #删
deploy-demo-76d96b77bb-cs2jq   0/1     Terminating         0          35m

[root@master ~]# kubectl get rs    #多了一个rs ----即多了一个版本，原来的副本数量变成了0，新的变成了2，可以用于回滚
NAME                     DESIRED   CURRENT   READY   AGE
deploy-demo-76d96b77bb   0         0         0       38m
deploy-demo-8d4c45d5f    2         2         2       2m35s

[root@master ~]# kubectl rollout history deployment deploy-demo  #查看版本
deployment.extensions/deploy-demo
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

# 用patch命令，打补丁的方式，更新资源---patch的参数是json格式的----可以直接edit或者用set，这里为了跟随教程练习命令，也操作一下
# 用patch 增加副本数量
[root@master ~]# kubectl patch deployments deploy-demo -p '{"spec":{"replicas":5}}'
deployment.extensions/deploy-demo patched

[root@master ~]# kubectl get deployments.
NAME          READY   UP-TO-DATE   AVAILABLE   AGE
deploy-demo   5/5     5            5           50m

####模拟滚动更新，更新几个pod后，暂停更新

#设置最多允许超过副本数量1个，不允许小于副本数量，即maxSurge=1 maxUnavailable=0，即保证有"副本数量"个pod一直能提供服务
[root@master ~]# kubectl patch deployments deploy-demo -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":1,"maxUnavailable":0}}}}'
deployment.extensions/deploy-demo patched

[root@master ~]# kubectl describe deployments deploy-demo
RollingUpdateStrategy:  0 max unavailable, 1 max surge

#下面用set命令修改镜像版本，然后用rollout pause命令暂停更新----这样可以实现只更新部分pod，即一部分pod用旧版本，一部分用新版本
[root@master ~]# kubectl set image deployment deploy-demo deploy-demo-pod=ikubernetes/myapp:v3 && kubectl rollout pause deployment deploy-demo
# 注意set命令的格式  kubectl set image  资源类别 资源名称 容器名=镜像版本   ---因为pod可以包含多个容器

[root@master ~]# kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
deploy-demo-5cbb8fd576-57rjk   1/1     Running   0          23s   #这个是新增加的，而且其他pod没有被删除，因为升级被暂停了
deploy-demo-8d4c45d5f-5r6bh    1/1     Running   0          30m
deploy-demo-8d4c45d5f-hqbl6    1/1     Running   0          30m
deploy-demo-8d4c45d5f-p6ktd    1/1     Running   0          16m
deploy-demo-8d4c45d5f-whdjs    1/1     Running   0          16m
deploy-demo-8d4c45d5f-xhhdk    1/1     Running   0          16m

# 用rollout resume命令继续更新
[root@master test]# kubectl rollout resume deployment deploy-demo
deployment.extensions/deploy-demo resumed

# 用rollout status查看更新状态
[root@master ~]# kubectl rollout status deployment deploy-demo
Waiting for deployment "deploy-demo" rollout to finish: 1 out of 5 new replicas have been updated...
Waiting for deployment spec update to be observed...
Waiting for deployment spec update to be observed...
Waiting for deployment "deploy-demo" rollout to finish: 1 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 1 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "deploy-demo" rollout to finish: 1 old replicas are pending termination...
deployment "deploy-demo" successfully rolled out

[root@master test]# kubectl rollout history deployment deploy-demo
deployment.extensions/deploy-demo
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>

[root@master test]# kubectl get rs -o wide
NAME                     DESIRED   CURRENT   READY   AGE     CONTAINERS          IMAGES                 SELECTOR
deploy-demo-5cbb8fd576   5         5         5       9m10s   deploy-demo-pod     ikubernetes/myapp:v3   app=deploy-demo,pod-template-hash=5cbb8fd576,release=canary
deploy-demo-76d96b77bb   0         0         0       71m     deploy-demo-pod     ikubernetes/myapp:v1   app=deploy-demo,pod-template-hash=76d96b77bb,release=canary
deploy-demo-8d4c45d5f    0         0         0       36m     deploy-demo-pod     ikubernetes/myapp:v2   app=deploy-demo,pod-template-hash=8d4c45d5f,release=canary
rs-demo                  4         4         4       178m    rs-demo-container   ikubernetes/myapp:v1   app=rs-demo,release=canary



# 用rollout undo回滚，如果不加--to-revision，默认回到上一版本
[root@master test]# kubectl rollout undo deployment deploy-demo

[root@master ~]# kubectl rollout status deployment deploy-demo
Waiting for deployment "deploy-demo" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 2 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 3 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 4 out of 5 new replicas have been updated...
Waiting for deployment "deploy-demo" rollout to finish: 2 old replicas are pending termination...
Waiting for deployment "deploy-demo" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "deploy-demo" rollout to finish: 1 old replicas are pending termination...
deployment "deploy-demo" successfully rolled out




