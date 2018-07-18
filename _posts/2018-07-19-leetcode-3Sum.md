---
layout: post
title: leetcode 3Sum
date: 2018-07-19 17:29:08
key: 20171019
tags: LeetCode
---

``` shell
Given an array nums of n integers, are there elements a, b, c in nums such that a + b + c = 0? Find all unique triplets in the array which gives the sum of zero.

Note:

The solution set must not contain duplicate triplets.

给定一个包含 n 个整数的数组 nums，判断 nums 中是否存在三个元素 a，b，c ，使得 a + b + c = 0 ？找出所有满足条件且不重复的三元组。

注意：答案中不可以包含重复的三元组。

例如, 给定数组 nums = [-1, 0, 1, 2, -1, -4]，

满足要求的三元组集合为：
[
  [-1, 0, 1],
  [-1, -1, 2]
]
```

``` go
//双指针
func threeSum(nums []int) [][]int {
    lens := len(nums)
    res := [][]int{}
    sort.Ints(nums)
    for left := 0; left < lens - 2; left++ {
        if left > 0 && nums[left] == nums[left-1] {
            continue
        }
        mid := left + 1
        right := lens - 1
        for mid < right {
            if mid > left + 1 && nums[mid] == nums[mid - 1] {
                mid++
                continue
            }
            if nums[mid] + nums[left] + nums[right] == 0 {
                res = append(res, []int{nums[left], nums[mid], nums[right]})
                mid++
                right--
            } else if nums[mid] + nums[left] + nums[right] < 0 {
                mid++
            } else {
                right--
            }
        }
    }
    return res
}
时间复杂度O(nlogn)
空间复杂度O(1)
```
