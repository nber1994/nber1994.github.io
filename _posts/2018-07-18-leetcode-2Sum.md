---
layout: post
title: leetcode 2Sum
date: 2018-07-18 17:29:08
key: 20171019
tags: LeetCode
---

``` shell
Given an array of integers, return indices of the two numbers such that they add up to a specific target.
You may assume that each input would have exactly one solution, and you may not use the same element twice.

给定一个整数数组和一个目标值，找出数组中和为目标值的两个数。你可以假设每个输入只对应一种答案，且同样的元素不能被重复利用。

Example:

Given nums = [2, 7, 11, 15], target = 9,

Because nums[0] + nums[1] = 2 + 7 = 9,
return [0, 1]. 
```

```go
//双指针
func twoSum(nums []int, target int) []int {
    lens := len(nums)
    oldNums := make([]int, lens)
    copy(oldNums[:], nums)
    left := 0
    right := lens - 1
    //先进行排序, 升序
    sortedNums := sort.IntSlice(nums)
    sort.Stable(sortedNums)
    for left < right {
        for {
            if sortedNums[left] + sortedNums[right] <= target {
                break;
            }
            right--
        }
        if sortedNums[left] + sortedNums[right] == target {
            break;
        }
        for {
            if sortedNums[left] + sortedNums[right] >= target {
                break;
            }
            left++
        }
        if sortedNums[left] + sortedNums[right] == target {
            break;
        }
    }
    //查找key
    res := []int{}
    for k, v := range oldNums {
        if v == sortedNums[left] || v == sortedNums[right] {
            res = append(res, k)
        }
    }
    return res
}

//时间复杂度O(logn)
//空间复杂度O(n) 因为进行排序，新生成了一个slice
```

``` go
//一遍hash遍历

func twoSum(nums []int, target int) []int {
    hashMap := make(map[int]int, len(nums))
    res := make([]int, 2)
    for k, v := range nums {
        pom := target - v
        if index, exist := hashMap[pom]; exist{
            res[1] = k
            res[0] = index
            return res
        }
        hashMap[v] = k
    }
    return res
}

时间复杂度为O(n)
空间复杂度为O(n)
```
