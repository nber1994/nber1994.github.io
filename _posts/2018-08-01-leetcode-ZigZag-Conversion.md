---
layout: post
title: ZigZag Conversion
date: 2018-08-01 17:29:08
key: 20180801
categories: leetcode
---

```shell
The string "PAYPALISHIRING" is written in a zigzag pattern on a given number of rows like this: (you may want to display this pattern in a fixed font for better legibility)
将字符串 "PAYPALISHIRING" 以Z字形排列成给定的行数：

P   A   H   N
A P L S I I G
Y   I   R
之后从左往右，逐行读取字符："PAHNAPLSIIGYIR"

实现一个将字符串进行指定行数变换的函数:

string convert(string s, int numRows);
示例 1:

输入: s = "PAYPALISHIRING", numRows = 3
输出: "PAHNAPLSIIGYIR"
示例 2:

输入: s = "PAYPALISHIRING", numRows = 4
输出: "PINALSIGYAHRPI"
解释:

P     I    N
A   L S  I G
Y A   H R
P     I
```

```go
func convert(s string, numRows int) string {
        sArr := []byte(s)
    if len(sArr) < 2 || numRows == 1 {
        return s
    }
    resArr := []byte{}
    step := 2*numRows - 2
    for i := 0; i < numRows; i++ {
            for j := 0; j+i < len(sArr); j = j + step {
                    resArr = append(resArr, sArr[j+i])
                    if i != 0 && i != numRows-1 && j+step-i < len(sArr) {
                            resArr = append(resArr, sArr[j+step-i])
                    }
            }
    }
    return string(resArr)
}
//时间复杂度O(n)
//空间复杂度O(n)
```
