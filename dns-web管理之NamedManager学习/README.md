# DNS web管理工具之NamedManager

## 概述
  - bind是提供域名解析服务的软件
  - NamedManager是一个配置bind的web页面，使用的语言是php
  - NamedManager包含另个主要模块 NamedManager-bind和 NamedManager-www
  - 比较适用于自己搭建内网使用的域名解析服务器
  - 大致的组成部分包括 mysql+bind+httpd+NamedManager
  
## 参考信息

- https://blog.51cto.com/gdutcxh/2109195
- https://github.com/jethrocarr/namedmanager/wiki/Installation-RPM
- https://repos.jethrocarr.com/pub/amberdms/linux/centos/7/jethrocarr-custom/

## 部署

### 环境说明
  - 使用CentOS 7.6 作为服务器，通过yum安装需要的程序
  
### 安装步骤
  1. 主机名设置[可选]
    - 设置主机名
  2. 配置yum源(也可以手动rpm命令安装，但是需要自己解决依赖关系)

``` bash
    yum-config-manager --add-repo=https://repos.jethrocarr.com/pub/amberdms/linux/centos/7/jethrocarr-custom/x86_64/
    # 可以手动修改下repo名称什么的,添加gpgcheck=0
```

  3. 安装软件
``` bash
  yum install namedmanager-bind  namedmanager-www   #它的依赖包中，包含了bind、php、httpd等，比较省事
```

  4. 设置开机自启
``` bash
  systemctl enable named httpd mariadb
```
  
  5. 数据库初始化
``` bash
  systemctl start mariadb  #启动数据库
  mysql_secure_installation  #设置root用户密码，并删除无用的库
  cd /usr/share/namedmanager/resources/; ./autoinstall.pl   # 初始化NamedManager数据库，注意输入root用户密码；这个初始化文件，会新建数据库以及用户，并且会自动修改NamedManager的配置文件
```

  6. 配置bind
``` bash
  echo 'include "/etc/named.namedmanager.conf";' >>  /etc/named.conf
  vim /etc/named.conf 
  默认是监听到127上，改成any，允许查询也是
  listen-on port 53 { 127.0.0.1; };   --> listen-on port 53 { any; };
  allow-query     { localhost; };  --> allow-query     { any; };
  
  # 如果使用bind-chroot功能，需要执行下面语句
  # yum install bind-chroot 
  # ln /etc/named.namedmanager.conf /var/named/chroot/etc/named.namedmanager.conf  #创建硬链接，因为chroot之后，根发生了改变
  
  systemctl start named  #启动named服务
```

  7. 配置NamedManager-bind
``` bash
  vim /etc/namedmanager/config-bind.php
  ...
  $config["api_url"]              = "http://192.168.36.190/namedmanager";   #访问地址              
  $config["api_server_name"]      = "ns1.maleilearn.com";                       #设置为 为这台dns服务器分配的域名---在页面上设置的时候，需要跟这个保持一致     
  $config["api_auth_key"]         = "DNS";                                  #key，随便填---在页面上设置的时候，需要跟这个保持一致   
  ...
``` 

  8. 配置httpd
``` bash
  vim /etc/httpd/conf/httpd.conf 
  <Directory />
    AllowOverride none
    # Require all denied   # 默认是这个，注释掉，拒绝所有访问
    Require all granted     # 添加这行，允许所有访问
</Directory>

  systemctl restart httpd
```

### web端使用 

  1. 登录
  > 访问地址 http://192.168.36.190/namedmanager  
  > 默认的用户名密码  setup/setup123
  > 登录之后，先去修改用户名和密码，比如改成admin/123123什么的
  
  2. 配置 
    - 在 configuration 菜单，设置之前在config-bind.php里配置的api key值
    - 在 Name Server 菜单，添加新server，设置name server fqdn，即在config-bind配置的api_server_name,设置api key值
    - 配置好之后，NamedManager会一分钟同步一次配置文件和日志文件到bind，注意观察server status
    - 在 Domains/Zones 菜单，添加正向解析(standard domain)，输入域名部分，如maleilearn.com ；然后添加反向解析(reverse domain),输入要反向解析的ip端，比如192.168.36.0/24
    - 添加解析记录，在添加好的domains/zones里，正向解析的那行，有domain recored，添加a记录，比如name是www,content是192.168.36.3，勾选reverse PTR之后，会自动添加相应的反向解析
    - 添加成功之后，可以去/var/named/目录查看生成的maleilearn.com.zone以及反向解析用的36.168.192.in-addr.arpa.zone 
  3. 验证
    - 方法一： 命令nslookup
``` bash
    语法：nslookup   要解析的地址   dns服务器地址
    nslookup www.maleilearn.com 192.168.36.190  可以得到192.168.36.3
    nslookup 192.168.36.3  192.168.36.190  www.maleilearn.com
```
    - 方法二： 正常使用
``` bash    
    给客户端电脑配置dns地址为搭建的NamedManager服务器地址，即192.168.36.190，然后通过浏览器访问配置的那些域名
```


    

  
  
