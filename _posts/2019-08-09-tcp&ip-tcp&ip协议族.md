--- 
layout: post 
title: tcp&ip-tcp&ip协议族 
tags: tcp&ip 
---
# tcp&ip-tcp&ip协议族
> tcp和ip是互相互补的

## TCP协议
tcp基于字节流的传输层协议，位于应用层之下，完成的是IP协议完成不了的可靠传输

## IP协议
IP协议是不可靠的，负责在原地址和目的地址之间传输，他只关心跨越本地网络边界问题，寻址和路由

## 分层
* 应用层
    * http 
    * ftp 
    * telnet 
    * dns
* 传输层
    * tcp
    * udp
* 网络层
    * IP 负责路由寻址
    * ARP 地址解析协议获取统一物理网络中的物理地址
    * ICMP 控制消息协议 传送错误和控制信息
    * IGMP 组管理协议 用来实现本地广播
* 数据链路层
