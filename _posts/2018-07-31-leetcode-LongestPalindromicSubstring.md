---
layout: post
title: leetcode Longest Palindromic Substring
date: 2018-07-31 17:29:08
key: 20171031
categories: LeetCode
---
```shell
Given a string s, find the longest palindromic substring in s. You may assume that the maximum length of s is 1000. 

给定一个字符串 s，找到 s 中最长的回文子串。你可以假设 s 的最大长度为1000。

示例 1：

输入: "babad"
输出: "bab"
注意: "aba"也是一个有效答案。
示例 2：

输入: "cbbd"
输出: "bb"
```

```go
//manacher算法
func longestPalindrome(s string) string {
    if s == "" {
        return ""
    }
    byteArr := []byte(s)
    byteArrArr := bytes.Split(byteArr, []byte{})
    sArr := bytes.Join(byteArrArr, []byte{'#'})
    sArr = append(sArr, 35)
    sArr = append([]byte{'#'}, sArr...)
    maxRight, mid, maxP, miden := 0, 0, 0, 0
    p := map[int]int{}
    for i := 1; i < len(sArr)-1; i++ {
        if i < maxRight {
                if p[2*mid-i] < maxRight-i {
                        p[i] = p[2*mid-i]
                } else {
                        p[i] = maxRight - i
                }
        } else {
                p[i] = 1
        }
        for i+p[i] <= len(sArr)-1 && i-p[i] >= 0 && sArr[i+p[i]] == sArr[i-p[i]] {
                p[i]++
        }
        if i+p[i] > maxRight {
                maxRight = i + p[i]
                mid = i
        }
        if maxP < p[i] {
                maxP = p[i]
                miden = i
        }
    }
    return strings.Replace(string(sArr[miden-maxP+1:miden+maxP]), "#", "", -1)
}
//时间复杂度O(n)
//空间复杂度O(n)
```
