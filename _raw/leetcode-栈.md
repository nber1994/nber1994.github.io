--- 
layout: post 
title: leetcode-栈 
date: 2019-03-11 15:34:44 
categories: leetcode 
---
# leetcode-栈
```go
package main

import "fmt"

func main() {
        a := &TreeNode{7, nil, nil}
        b := &TreeNode{3, nil, nil}
        c := &TreeNode{15, nil, nil}
        d := &TreeNode{9, nil, nil}
        e := &TreeNode{20, nil, nil}
        a.Left = b
        a.Right = c
        c.Left = d
        c.Right = e
        obj := Constructor(a)
        for obj.HasNext() {
                fmt.Println(obj.Next())
        }
}

type TreeNode struct {
        Val   int
        Left  *TreeNode
        Right *TreeNode
}

//实现一个二叉搜索树迭代器。你将使用二叉搜索树的根节点初始化迭代器。
//
//调用 next() 将返回二叉搜索树中的下一个最小的数。
//
//BSTIterator iterator = new BSTIterator(root);
//iterator.next();    // 返回 3
//iterator.next();    // 返回 7
//iterator.hasNext(); // 返回 true
//iterator.next();    // 返回 9
//iterator.hasNext(); // 返回 true
//iterator.next();    // 返回 15
//iterator.hasNext(); // 返回 true
//iterator.next();    // 返回 20
//iterator.hasNext(); // 返回 false
//
//
//提示：
//
//next() 和 hasNext() 操作的时间复杂度是 O(1)，并使用 O(h) 内存，其中 h 是树的高度。
//你可以假设 next() 调用总是有效的，也就是说，当调用 next() 时，BST 中至少存在一个下一个最小的数。

/**
 * Definition for a binary tree node.
 * type TreeNode struct {
 *     Val int
 *     Left *TreeNode
 *     Right *TreeNode
 * }
 */
type BSTIterator struct {
        stack []*TreeNode
        size  int
}

func (this *BSTIterator) Push(v *TreeNode) {
        this.stack = append(this.stack, v)
        this.size++
}

func (this *BSTIterator) Pop() *TreeNode {
        if this.size == 0 {
                return nil
        }
        res := this.stack[this.size-1]
        this.stack = this.stack[:this.size-1]
        this.size--
        return res
}

func Constructor(root *TreeNode) BSTIterator {
        myBSTIterator := new(BSTIterator)
        myBSTIterator.stack = []*TreeNode{}
        myBSTIterator.size = 0
        for root != nil {
                myBSTIterator.Push(root)
                root = root.Left
        }
        return *myBSTIterator
}

/** @return the next smallest number */
func (this *BSTIterator) Next() int {
        res := this.Pop()
        item := res.Right
        for item != nil {
                this.Push(item)
                item = item.Left
        }
        return res.Val
}

/** @return whether we have a next smallest number */
func (this *BSTIterator) HasNext() bool {
        return this.size > 0
}

/**
 * Your BSTIterator object will be instantiated and called as such:
 * obj := Constructor(root);
 * param_1 := obj.Next();
 * param_2 := obj.HasNext();
 */

```
