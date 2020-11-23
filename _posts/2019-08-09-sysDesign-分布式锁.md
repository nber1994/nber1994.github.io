--- 
layout: post 
title: sysDesign-分布式锁 
tags: sysDesign 
---
# sysDesign-分布式锁

## 分布式锁的一些原则
* 互斥性 最基本的
* 可重入性 同一个节点对于同一资源可以多次获取
* 锁超时 避免死锁

## 常见实现方式
* mysql
* redis

## mysql实现
```c
CREATE TABLE `resourceLock` (
    `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
    `resource_name` varchar(128) NOT NULL DEFAULT '' COMMENT '资源名字',
    `node_info` varchar(128) DEFAULT NULL COMMENT '节点信息',
    `count` int(11) NOT NULL DEFAULT '0' COMMENT '锁的次数 （可重入）',
    `desc` varchar(128) DEFAULT NULL COMMENT '资源描述',
    `mtime` timestamp NULL DEFAULT NULL,
    `ctime` timestamp NULL DEFAULT NULL,
    PRIMARY KEY (`id`),
    UNIQUE KEY `uniq_resource` (`resource_name`)
) ENGINE=InnoDB DEFAULT CAHRSET=utf8mb4;
```

### 加锁
查询xxx资源是否是当前节点所有，如果有的话则增加count
```c
transaction begin
res = select * from resourceLock where resource_name = xxx for update;
if res == nil 
    insert ....
    return true
if node_info == myNode 
    //更新次数
    update resourceLock set count = count+1 where resource_name = xxx
    commit
    return true
else
    commit
    return false
```
### 解锁
如果count为1则删除，大于一则减一
```c
transaction begin
select * from resourceLock where resource_name=xxx for update;
if count > 1
    update count = count-1
else 
    delete 
```

### 锁超时
#### 惰性解锁
可以在试图加锁的时候，首先检测锁是否超时，超时则解锁
#### 定时解锁
离线的脚本来定时的去解锁超时的锁

### 小结
* 该方案适用于资源不存在数据库中场景，如果例如订单本身就落地于数据库的话，可以直接在行数据上加锁即可
* 该方案理解简单
* 实现比较复杂，需要自己考虑锁超时等情况，并且性能依赖于数据库，性能较低
    * 可以考虑使用乐观锁来实现，在并发不是那么大的时候，乐观锁可以避免锁竞争带来的性能损失
        * 为每个资源设置一个数据版本
