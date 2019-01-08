---
layout: post
title: leetcode Longest Substring Without Repeating Characters
date: 2018-07-21 17:29:08
key: 20171021
categories: leetcode
---

```shell
Given a string, find the length of the longest substring without repeating characters.
给定一个字符串，找出不含有重复字符的最长子串的长度。

示例：

给定 "abcabcbb" ，没有重复字符的最长子串是 "abc" ，那么长度就是3。

给定 "bbbbb" ，最长的子串就是 "b" ，长度是1。

给定 "pwwkew" ，最长子串是 "wke" ，长度是3。请注意答案必须是一个子串，"pwke" 是 子序列  而不是子串。
```

```go
//窗口
func lengthOfLongestSubstring(s string) int {
    strArr := []byte(s)
    byteMap := make(map[byte]int, 0)
    lens := len(strArr)
    maxLen := 0
    left := 0
    right := 0
    for right < lens {
        if _, exist := byteMap[strArr[right]]; exist {
            if byteMap[strArr[right]] >= left {
                left = byteMap[strArr[right]] + 1
            }
        }
        byteMap[strArr[right]] = right
        if right - left + 1 > maxLen {
            maxLen = right - left + 1
        }
        right++
    }
    return maxLen
}
//时间复杂度O(n)
//空间复杂度O(n)
```
