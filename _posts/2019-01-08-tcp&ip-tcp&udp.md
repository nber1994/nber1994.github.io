--- 
layout: post 
title: tcp&ip-tcp&udp 
date: 2019-01-08 01:24:23 
categories: tcp&ip 
---
# tcp&udp
- tcp/ip或者udp/ip中，唯一确认一个连接为五个元素
    - 源IP
    - 源端口号
    - 协议
    - 目的IP
    - 目的端口号
## 端口号
- 既定端口号
    - telnet 23
    - ssh 22
    - fpt 21
    - http 80
    - mysql 3306
    - redis 6379
- 时序分配
    - 交给操作系统进行分配
# udp
- 无连接
- 没有流量控制
- 不保证包的顺序性
## 应用场景
- 即时通信
- 广播通信
- 包总量较少通信
# tcp
- 充分实现了数据传输时的各种控制功能
    - 丢包重传
    - 分包保持顺序
    - 面向连接

## 通过序列号和确认应答提高可靠性
### 确认应答
- 接受端收到消息后会返回一个已经收到的消息通知，叫做ACK
- 如果收到的消息不理解则会返回一个NACK
- 发送端发送一段时间之后没有收到ACK消息，则可以认定数据已经丢失，并进行重发
    - 但是没有收到ACK也并不代表消息没有到达，也有可能是ack丢失
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128111354090_32064378.png)
    - 这种情况下也会导致发送端以为数据没有到达，进行重发
    - 这种情况下，即使ack返回延迟了，发送端仍会重发包，而对于接收端来说
        - 会受到重复数据，需要对数据进行去重
### 序列号
- 确认应答处理，重发控制，重复控制
- 序列号为每一个字节添加一个编号
- 接收端查询接收数据首部的序列号和数据长度，并将自己下一步应该接收的序号作为应答返回
- 通过序列号和确认应答号，实现可靠传输
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128115519314_2035089296.png)
## 重发超时如何确定
- 理想是找到一个最小时间，保证在该段时间内确认包一定能返回
- 但是该时间会根据网络情况不同而不同
- 每次发包都会计算往返时间和偏差
- 重发时间就是往返时间加上偏差时间稍微大一点
- 一般超时重发时间都是0.5秒的整数倍，最初还不知道往返时间，超时时间设置为6秒左右
- 数据重发之后，若还未收到应答，超时时间则会以2，4指数增长
- 在重发了一定次数后，强制关闭连接
## 连接管理
- tcp是面向连接的，其意思是在通信开始之前先做好之间的准备工作
- 一个tcp连接的建立和断开，至少需要7个包才能完成
## 以段为单位发送数据
- tcp建立连接的时候，也可以确认发送数据包的单位，即MSS
- 传输数据时，是按照MSS进行数据分割的
- MSS会在三次握手时，在两端主机之间计算得出，两端在建立连接时，会在tcp首部添加自己可以接受的MSS值，取最小值
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128140102743_773752103.png)
## 利用窗口控制提高速度
- 问题
    - tcp已一个段作为单位，没发一个段进行一次确认应答的处理
    - 这样会有一个问题，包的往返时间越长，通信的性就越低
- 解决方案
    - 引入窗口的概念
    - 确认应答不再是以每个分段，而是以更大的单位进行确认，这样发送一个段之后，不需要等待应答，而可以继续发送
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128141825497_1438112536.png)
- 窗口中的段即使没有收到确认也可以发送出去
- 同时，还需要使用缓存，将未发送和为应答的数据缓存起来
- 已经发送并收到应答的段可以从缓存中删除
- 收到确认信息后，将滑动窗口滑到确认的段
## 窗口控制与重发控制
- 在窗口模式下，即使某个段没有收到确认应答，也不会重发
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128142449821_428945567.png)
- 当数据包在中途丢失时，例如1001-2000包丢失之后，接收端会一直返回下一个是1001
- 这种情况下一个序号会被反复的应答，当发送端连续收到3次同一个确认应答时，就会将对应数据进行重发
- 这种方式比之前的超时重发来的更高效，这种犯法叫做高速重发
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128144201011_185541590.png)
## 流控制
- 接收端可能负荷太高，而导致不能及时接受数据
- 发送端根据接收端实际的接受能力来发送数据，叫做流控制
- 接收端向发送端主机通知自己可以接受数据的大小，即自己的窗口大小
- 发送端会根据接收端发送的窗口大小来发送数据到接收端
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128145009016_251247686.png)
- 由图可以看出，当接收方的窗口大小在逐渐变小到0时，接收端会停止发送，等到超时重发时间之后，会发送一个窗口探测包来获取窗口大小
- 同时由于窗口探测宝如果丢失了则会导致通信无法继续，于是窗口探测宝是时不时发送
## 拥塞控制
- 当使用窗口进行数据发送时，当通信初期就发生大量数据，也会引发一定问题
    - 网络为共享网络，可能由于其他主机的通信导致网络拥堵，此时发送大量的数据，可能导致整个网络的瘫痪
- 在发送初期，定义了拥塞窗口，初始为1MSS，之后每次收到ACK，窗口就加一
- 发送数据包时，按照接收端窗口和拥塞窗口大小的最小值发送
- 同时为了防止拥塞窗口过大，设置了窗口阈值，超过这个值之后，没收到一次确认应答，只允许以一下比例发达窗口
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128150644296_767008600.png)
- 慢启动阈值一般是在第一次超时重发时设置的，设置为当时拥塞窗口大小的一般
- 由重复确认应答而进行高速重发控制时，慢启动的阈值大小被设置为当前窗口的一半，然后窗口的大小设置为慢启动阈值+3MSS的大小
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128151926903_1916690906.png)
- 首次达到重发超时时，阈值被设置为当时的一半，拥塞窗口从0开始递增
- 同时拥塞窗口在指数上升
- 当发生了三次重复确认触发了高速重发时，拥塞窗口被设置为一般，并把窗口设置为了窗口一般+3MSS
- 之后又发生了超时重发，拥塞窗口再次变为了0
## 提高网络利用率规范
- nagle算法
    - 即使发送端存在应该发送的数据，但是数据量很小时，采取延迟发送的一种做法
    - 发送条件为下列之一
        - 已发送的数据都已经收到确认应答时
        - 可以发送的最大段长度（MSS）的数据时
    - 可以提高网络利用率，但是会导致一定的延迟
- 延迟确认应答
    - 如果每次收到数据包后就发生确认应答的话，可能会返回一个较小的窗口
    - 延迟一点时间来返回确认应答，可以增大窗口大小
    - 同时并不需要每个数据包都确认应答，一般两个数据包发出一个确认应答即可
- 捎带应答
    - 在使用tcp的应用中如果也存在需要确认应答的场景
    - 可以将应用的确认应答和tcp的确认应答合并为一个包来进行应答
![](https://cdn.jsdelivr.net/gh/nber1994/fu0k@master/uPic/20181128161514391_1569352142.png)