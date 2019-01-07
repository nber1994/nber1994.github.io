---
layout: post
title: leetcode addTwoNumbers
date: 2018-07-20 17:29:08
key: 20171020
categories: LeetCode
---

```shell
You are given two non-empty linked lists representing two non-negative integers. The digits are stored in reverse order and each of their nodes contain a single digit. Add the two numbers and return it as a linked list.

You may assume the two numbers do not contain any leading zero, except the number 0 itself.
给定两个非空链表来表示两个非负整数。位数按照逆序方式存储，它们的每个节点只存储单个数字。将两数相加返回一个新的链表。

你可以假设除了数字 0 之外，这两个数字都不会以零开头。

示例：

输入：(2 -> 4 -> 3) + (5 -> 6 -> 4)
输出：7 -> 0 -> 8
原因：342 + 465 = 807
```

```go
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func addTwoNumbers(l1 *ListNode, l2 *ListNode) *ListNode {
    forward := 0
    now := &ListNode{}
    first := now
    i := 0
    for {
        //当两个都已经为nil
        if l1 == nil && l2 == nil {
            if forward > 0 {
               //当存在进位时 
                now.Next = &ListNode{Val:forward}
            } 
            break
        }
        tmpNode := &ListNode{}
        if l1 == nil {
            tmpNode.Val = (l2.Val + forward) % 10
            forward = (l2.Val + forward) / 10
        } else if l2 == nil {
            tmpNode.Val = (l1.Val + forward) % 10
            forward = (l1.Val + forward) / 10
        } else {
            sum := l1.Val + l2.Val
            tmpNode.Val = (sum + forward) % 10
            forward = (sum + forward) / 10
        }
        if i == 0 {
            now = tmpNode
            first = now
        } else {
            now.Next = tmpNode
            now = tmpNode
        }
        i++
        if l1 != nil {
            l1 = l1.Next 
        }
        if l2 != nil {
            l2 = l2.Next 
        }
    }
    return first
}
//时间复杂度O(n)
//空间复杂度O(n)
```

```go
//leetcode best
/**
 * Definition for singly-linked list.
 * type ListNode struct {
 *     Val int
 *     Next *ListNode
 * }
 */
func addTwoNumbers(l1 *ListNode, l2 *ListNode) *ListNode {
    beforeHeadNode := &ListNode{}
    beforeHeadP := beforeHeadNode
    forward := 0
    for l1 != nil || l2 != nil || forward != 0 {
        sum := forward
        forward = 0
        if l1 != nil {
            sum += l1.Val
            l1 = l1.Next
        } 
        if l2 != nil {
            sum += l2.Val
            l2 = l2.Next
        }
        if sum > 9 {
            sum = sum - 10
            forward = 1
        }
        nowNode := &ListNode{
            Val: sum,
            Next: nil,
        }
        beforeHeadNode.Next = nowNode
        beforeHeadNode = nowNode
    }
    return beforeHeadP.Next
}
//时间复杂度O(n)
//空间复杂度O(n)
```
