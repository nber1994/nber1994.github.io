---
layout: post
title: 如何获取php引用的所有脚本
tags: php
---

获取所有的引入文件，一般这句放在controller的结束位置

```
$included_files = get_included_files();
file_put_contents('/tmp/dArrive',implode("\r\n", $included_files));
```

