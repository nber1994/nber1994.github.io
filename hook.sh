#!/bin/bash
rawPath=$1
targetPath=$2
tags_arr=("redis" "mysql" "tcp&ip" "shell" "os" "sysDesign" "pic" "leetcode" "nginx" "php" "java" "go" "else" "vim")

for tag in ${tags_arr[@]} 
do
    if [ -d "${rawPath}/${tag}" ]; then
        # 拷贝文件
        find ${rawPath}/${tag} -name '*.md'   | while read -r; \
        do PRE=`stat -f %SB -t %Y-%m-%d "$REPLY"`; \
            BASE=`basename "$REPLY"`; \
            echo "正在处理: "$PRE'-'$BASE
            cp "$REPLY" $2/_posts/$PRE'-'$BASE; done
    fi
done
