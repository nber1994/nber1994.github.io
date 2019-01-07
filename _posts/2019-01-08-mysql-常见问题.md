--- 
layout: post 
title: mysql-常见问题 
date: 2019-01-08 01:24:17 
categories: mysql 
---

## innoDB和MyIsAm引擎的区别


## 什么是存储过程，视图，触发器和事件  
### 存储过程
存储过程就是一组完成特定功能的sql语句集合，经过编译后存储在mysql中，通过名字+参数进行调用
但是mysql的存储过程相对较弱使用较少

视图
视图两种方式，一个是简历临时表，另一个是合并算法
## 主键的作用， 索引，内存管理 

## 外键完整性约束

## join 链接
![](/images/20181102201848044_1116699279.png)

join和inner join是等价的  
Mysql只支持两种内连接和外连接  

对于left join来说，类似  
slelect  on where  
**会先根据on条件生成临时表**
**where在临时表的基础上进行数据筛选**
所以连表查询会建立临时表  
