---
layout: post
title: Reverse Integer
date: 2018-08-02 17:29:08
key: 20180802
categories: leetcode
---

```shell
Given a 32-bit signed integer, reverse digits of an integer.
给定一个 32 位有符号整数，将整数中的数字进行反转。

示例 1:

输入: 123
输出: 321
 示例 2:

输入: -123
输出: -321
示例 3:

输入: 120
输出: 21
注意:

假设我们的环境只能存储 32 位有符号整数，其数值范围是 [−231,  231 − 1]。根据这个假设，如果反转后的整数溢出，则返回 0。
```

```go
const (
        MAX int32 = 1<<31 - 1
        MIN       = -MAX - 1
)

func reverse(x int) int {
        var ret int32
        var sign int32
        sign = 1
        ret = 0
        x32 := int32(x)
        if x32 < int32(0) {
                sign = int32(-1)
                x32 = x32 * int32(-1)
        }
        for x32 != int32(0) {
                if ret != int32(0) && (MAX/ret < int32(10) || MAX-ret*int32(10) < x32%int32(10)) {
                        return 0
                }
                ret = ret*int32(10) + x32%int32(10)
                x32 = x32 / int32(10)
        }
        return int(ret * sign)
}
//时间复杂度O(n)
```
