---
layout: post
title: lnmp报错too-big-header错误探究
date: 2018-01-08 10:29:08
key: 20171020
tags: LNMP
---

> 之前遇到的一个偶发的错误，探讨下到底是怎么肥四

# 1.背景

遇到nginx报出了如下的error，导致服务为502 bad gateway

```php
2018/01/08 15:50:20 [error] 15477#0: *2941700922 upstream sent too big header while reading response header from upstream, client: xx.xx.xxx, server: test.com, request: "POST /test/test HTTP/1.1", upstream: "fastcgi://127.0.0.1:xxxx", host: "xxxxxx", referrer: "xxxxxx"
```
一时之间不知道原因，唯一有异常的是warninig日志较多，推测可能是php-fpm会把warning日志加到response header头里,导致头部过大报错

php代码中存在类似与以下的错误片段：

```php
<?php
    $a = [
        'a' => '123',
        'b' => '123',
        'c' => '123',
        'd' => '123',
    ];

    foreach ($a['nber1994'] as $item) {
        /**
            do something...
        */    
    }
``` 

此时会报warning的错误，类似于

```php
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
PHP message: PHP Warning:  Invalid argument supplied for foreach() in XXXXX.php on line 206
```
**大量的warning如果会被加到header头里的话，肯定会触发nginx的相关配置(如果有的话),导致报错,看起来解释的通**
但是是否真的是因为header头过大导致的呢，探究一下

# 2.抓取php-fpm与nginx之间的通信数据

我们知道，php-fpm与nginx之间的通信方式有两种，

## 以php监听端口通信
速度较unix socket较慢，但是支持跨机器调用

### ps:开放php端口对外提供fastcgi服务的方法

```shell
1.设置防火墙,开放你的端口
2.php-fpm配置增加：
listen = 公网IP:9085
listen.allowed_clients = 192.168.10.66 #设置允许连接到 FastCGI 的服务器 IPV4 地址。如果允许所有那么把这条注释掉即可
```
Done!
## 以unix socket方式通信
    速度较快，性能高

## 抓取方法

### 对于端口通信，可以直接采用tcpdump监听：

```shell
tcpdump -X -i any  port 9999 > /tmp/tcpdump.log
```

### 对于unix socket

```shell
cd /path/to/php.sock
mv php.sock php.sock.orig
socat -t100 -x -v UNIX-LISTEN:php.sock,mode=777,reuseaddr,fork UNIX-CONNECT:php.sock.orig
将socket通道的内容转发一份到另一个socket,进行监听
```
![抓到的数据](/pic/tcpdump.png)

可以看到php-fpm确实将warning传递给了nginx

# 3.猜测

php将过多的warning写入到了header里，导致超过了nginx配置的fastcgi_buffer_size的大小，导致报错，但是是这样吗

# 4.设法复现

该情况是线上问题，无法抓取到问题发生时，php-fpm与nginx之间到底发生了什么，所以准备在自己的开发环境复现

## 实现方案
不断的增大warning的数目，并监听端口与日志，截取502发生时，php-fpm到底传了什么给nginx

### php脚本

```php
<?php
for ($i = 0; $i<$_GET['iterations']; $i++)
        error_log(str_pad("a", $_GET['size'], "a"));
echo "got here\n";
```

### 请求方法

```shell
bash~ for it in {30..200..3}; do for size in {100..250..3}; do echo "size=$size iterations=$it $(curl -sv "http://localhost/debug.php?size=$size&iterations=$it" 2>&1 | egrep '^< HTTP')"; done; done | grep 502 | head

size=121 iterations=30 < HTTP/1.1 502 Bad Gateway
size=109 iterations=33 < HTTP/1.1 502 Bad Gateway
size=241 iterations=48 < HTTP/1.1 502 Bad Gateway
size=226 iterations=51 < HTTP/1.1 502 Bad Gateway
size=190 iterations=60 < HTTP/1.1 502 Bad Gateway
size=223 iterations=69 < HTTP/1.1 502 Bad Gateway
size=127 iterations=87 < HTTP/1.1 502 Bad Gateway
size=199 iterations=96 < HTTP/1.1 502 Bad Gateway
size=151 iterations=99 < HTTP/1.1 502 Bad Gateway
size=106 iterations=102 < HTTP/1.1 502 Bad Gateway 
```
不断的对脚本进行请求，使其向日志里写入更多的字节，同时过滤返回的502以及报错时的迭代次数与每次日志的大小
**单独说下，unix socket方式性能真的很高，这种unix socket通信的情况下，测试语句运行完了也没有报502**

### 监听日志

同时监听php绑定的端口，得到日志(此时，fastcgi_buffer_size 4K)

### tcpdump日志
可以顺便直观了解下tcp的三次握手:P
```shell
12:09:25.581210 IP 127.0.0.1.58984 > 127.0.0.1.9999: Flags [S], seq 3550696989, win 65495, options [mss 65495,sackOK,TS val 1133088550 ecr 0,nop,wscale 7], length 0
        0x0000:  4500 003c d93b 4000 4006 637e 7f00 0001  E..<.;@.@.c~....
        0x0010:  7f00 0001 e668 270f d3a3 561d 0000 0000  .....h'...V.....
        0x0020:  a002 ffd7 4619 0000 0204 ffd7 0402 080a  ....F...........
        0x0030:  4389 8f26 0000 0000 0103 0307            C..&........
12:09:25.581249 IP 127.0.0.1.9999 > 127.0.0.1.58984: Flags [S.], seq 457907882, ack 3550696990, win 65483, options [mss 65495,sackOK,TS val 1133088550 ecr 1133088550,nop,wscale 7], length 0
        0x0000:  4500 003c 0000 4000 4006 3cba 7f00 0001  E..<..@.@.<.....
        0x0010:  7f00 0001 270f e668 1b4b 1eaa d3a3 561e  ....'..h.K....V.
        0x0020:  a012 ffcb 396f 0000 0204 ffd7 0402 080a  ....9o..........
        0x0030:  4389 8f26 4389 8f26 0103 0307            C..&C..&....
12:09:25.581261 IP 127.0.0.1.58984 > 127.0.0.1.9999: Flags [.], ack 1, win 512, options [nop,nop,TS val 1133088550 ecr 1133088550], length 0
        0x0000:  4500 0034 d93c 4000 4006 6385 7f00 0001  E..4.<@.@.c.....
        0x0010:  7f00 0001 e668 270f d3a3 561e 1b4b 1eab  .....h'...V..K..
        0x0020:  8010 0200 602b 0000 0101 080a 4389 8f26  ....`+......C..&
        0x0030:  4389 8f26                                C..&
```

#### 报错的日志

```shell
2018/01/09 11:39:01 [error] 4207#0: *2045 FastCGI sent in stderr: "PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
2018/01/09 11:39:01 [error] 4207#0: *2045 upstream sent too big header while reading response header from upstream, client: 10.30.128.251, server: devathena.fang.lianjia.com, request: "GET /debug.php?size=121&iterations=30 HTTP/1.1", upstream: "fastcgi://127.0.0.1:9999", host: "devathena.fang.lianjia.com"
```

#### 正常的日志
```shell
2018/01/09 11:39:02 [error] 4207#0: *2353 FastCGI sent in stderr: "PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
PHP message: aaaaaaaaaaaaa
```

#### 紧张分析

上面的日志，一个是39:01，一个是39:02的，按照我们的测试脚本，时间越靠后，传递的日志量会越大，但是为什么数据量较小的39:01秒的日志触发了502，而数据量较大的39:02没有报错，而且，日志的量也是相同的，明显有截断，明显超出了4K，所以我们可以推测，其实fastcgi_buffer_size并不是一个检查值，超过这个值并不会报错。而更像是一个暂存的空间

# nginx发生了什么 

对于nginx配置文件中的fastcgi_buffer_size，文档中是这么写的

![文档](/pic/fastcgi_buffer_size.png)

其中 **the first part of the response received from the FastCGI server.**,这个参数指定的是接受到fastcgi-server端的第一部分的响应（一般是response header），在lnmp的场景里，fastcgi-server就是php部分，这个first part的含义是这样子的，由于upstream是一个通用的组件，因此它不知道后端的协议，而对于client来说，由于http是需要header的，而后端的协议不一定有头，此时就需要我们通过解析后端的协议，然后来设置好发送给client的头，最终发送给client 

以下是**the first part of the response**

![header](/pic/fastcgi-header.png)

* 对于接收到的来自后端服务器的响应头部。以上是一个fastcgi格式的响应报文，需要从fastcgi格式的报文中提取出http响应头部，因此需要经过状态机处理，从而解析出http响应头部。
* nginx接收后端服务的响应也应该是一种fastcgi报文格式。从图中可以看出，每一个http响应包头前面都加上了fastcgi头部，而每一个http响应包头都有可能由多条http响应头部组成。
* 我们暂且称每一个fastcgi头部 + http响应包头为一个组， nginx使用扫描法，扫描每一组。每一个组使用两个状态机，一个状态机解析这个组内的fastcgi头部， 另一个状态机解析这个组内的http响应包头，从而获取到每一个http响应头部。

## 报错位置的代码片段

![error](/pic/code.png)

## 处理头部的回掉函数伪代码

```c
//解析来自后端服务器发来的响应头部，从fastcgi格式转为nginx格式。
//采用两个状态机，一个解析fastcgi头部，一个解析fastcgi响应包头
static ngx_int_t ngx_http_fastcgi_process_header(ngx_http_request_t *r)
{
    //循环解析每一个组(fastcgi头部 + 多个http响应头部组成的数据)。因为每次从内核接收到的数据有可能包含多个组
    for ( ;; )
    {
        //解析fastcgi的头部
        if (f->state < ngx_http_fastcgi_st_data)
        {
            f->pos = u->buffer.pos;
            f->last = u->buffer.last;

            //使用状态解析fastcgi的头部
            rc = ngx_http_fastcgi_process_record(r, f);
            u->buffer.pos = f->pos;
            u->buffer.last = f->last;
        }

        //这个循环用于解析这个组内的每一个http响应头部。因此该组内的http响应包头可能由多个http响应头部组成。
        //而ngx_http_parse_header_line状态机每次只能解析一个http响应头部，因此需要循环解析
        for ( ;; )
        {
            //使用状态机解析来自后端服务器发来的http响应头部
            rc = ngx_http_parse_header_line(r, &u->buffer, 1);
            if (rc == NGX_OK)
            {
                //解析某个http响应头部成功后，保存到数组链表中
                /* a header line has been parsed successfully */
                h = ngx_list_push(&u->headers_in.headers);

                //保存http响应头部
                ngx_memcpy(h->key.data, r->header_name_start, h->key.len);
                //保存http响应头部的值
                ngx_memcpy(h->value.data, r->header_start, h->value.len);
                h->hash = r->header_hash;

                //如果是负责均衡模块支持的头部，则把常用头部的指针指向数组链表中相应位置
                hh = ngx_hash_find(&umcf->headers_in_hash, h->hash,
                                   h->lowcase_key, h->key.len);
                hh->handler(r, h, hh->offset);
            }

            //解析完成所有的响应头部，则保存响应状态码
            if (rc == NGX_HTTP_PARSE_HEADER_DONE)
            {
                if (u->headers_in.status)
                {
                    //后端服务器返回了状态码，则优先使用后端服务的响应状态码
                }
                else if (u->headers_in.location)
                {
                    //后端服务器返回了location,则需要给客户端返回302重定向
                }
                else
                {
                    //否则nginx构造200 0k返回给客户端
                    u->headers_in.status_n = 200;
                    ngx_str_set(&u->headers_in.status_line, "200 OK");
                }
            }
        }
    }
}
```
由代码可知，当两个状态机对fastcgi与http头解析如果出错的话（比如header头缺失）,也会返回NGX_AGAIN，如果当读取到php-fpm返回的header的尾部时，则会报错


## 盲目分析
我们回去看下之前监控的tcpdump的日志,发现

一次正常的日志
```shell
        0x0cf0:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x0d00:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x0d10:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x0d20:  6161 6161 610a 5048 5020 6d65 7373 6167  aaaaa.PHP.messag
        0x0d30:  653a 2061 6161 6161 6161 6161 6161 6161  e:.aaaaaaaaaaaaa
        0x0d40:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x0d50:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x0d60:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x0d70:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x0d80:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x0d90:  6161 6161 6161 610a 0000 0000 0106 0001  aaaaaaa.........
        0x0da0:  0024 0400 436f 6e74 656e 742d 7479 7065  .$..Content-type
        0x0db0:  3a20 7465 7874 2f68 746d 6c0d 0a0d 0a67  :.text/html....g
        0x0dc0:  6f74 2068 6572 650a 0000 0000 0103 0001  ot.here.........
        0x0dd0:  0008 0000 0000 0000 0061 6161            .........aaa
        12:09:25.585035 IP 127.0.0.1.9999 > 127.0.0.1.58984: Flags [F.], seq 3497, ack 721, win 523, options [nop,nop,TS val 1133088554 ecr 1133088551], length 0
        0x0000:  4500 0034 918f 4000 4006 ab32 7f00 0001  E..4..@.@..2....
        0x0010:  7f00 0001 270f e668 1b4b 2c53 d3a3 58ee  ....'..h.K,S..X.
        0x0020:  8011 020b 4fa2 0000 0101 080a 4389 8f2a  ....O.......C..*
        0x0030:  4389 8f27                                C..'
```

一次502的日志
```shell
        0x1f30:  6d65 7373 6167 653a 2061 6161 6161 6161  message:.aaaaaaa
        0x1f40:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1f50:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1f60:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1f70:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1f80:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1f90:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1fa0:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1fb0:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1fc0:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1fd0:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1fe0:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x1ff0:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x2000:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x2010:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x2020:  6161 6161 6161 6161 6161 6161 6161 6161  aaaaaaaaaaaaaaaa
        0x2030:  6161 610a                                aaa.
12:09:43.315839 IP 127.0.0.1.36564 > 127.0.0.1.9999: Flags [.], ack 40961, win 768, options [nop,nop,TS val 1133106285 ecr 1133106285], length 0
        0x0000:  4500 0034 c6d5 4000 4006 75ec 7f00 0001  E..4..@.@.u.....
        0x0010:  7f00 0001 8ed4 270f 363a 1573 0df7 5365  ......'.6:.s..Se
        0x0020:  8010 0300 e2df 0000 0101 080a 4389 d46d  ............C..m
        0x0030:  4389 d46d                                C..m
```

# 4.结论
观察上面的日志，报错的最后的响应头不完整或者根本就没有,这个正好会进入到nginx中未解析到header头并且已到header尾部的情况，触发报错
所以，暂时现在可以推断的是，php-fpm会在一定的情况下向nginx传送不完整的数据，导致502
至于提高fastcgi_buffer_size的值，为什么会减小这种报错几率的问题，需进一步探究
