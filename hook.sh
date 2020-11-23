#!/bin/bash
if [ x$1 != x ]
then
    rawPath=$1
else
    rawPath='./raw'
fi

if [ x$2 != x ]
then
    targetPath=$2
else
    targetPath='./'
fi

tags_arr=("redis" "mysql" "tcp&ip" "shell" "os" "sysDesign" "pic" "leetcode" "nginx" "php" "java" "go" "else" "vim")

for tag in ${tags_arr[@]} 
do
    if [ -d "${rawPath}/${tag}" ]; then
        # 拷贝文件
        find ${rawPath}/${tag} -name '*.md'   | while read -r; \
        do PRE=`stat -f %SB -t %Y-%m-%d "$REPLY"`; \
            BASE=`basename "$REPLY"`; \
            echo "正在处理: "$PRE'-'$BASE
            cp "$REPLY" $targetPath/_posts/$PRE'-'$BASE; done
    fi
done


if [ x$3 = x ]
then
    echo "发布..."
    cd $targetPath
    git status
    git add .
    git commit -m 'update'
    git push origin master
fi
