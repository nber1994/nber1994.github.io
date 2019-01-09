#!/bin/bash
# 拷贝文件
find '/Users/jingtianyou/Library/Mobile Documents/com~apple~CloudDocs/vNote/学习/' -name '*.md' -print0 | xargs -0 -J % cp % /Users/jingtianyou/github/Jekyll-Pithy/_raw/
find '/Users/jingtianyou/Library/Mobile Documents/com~apple~CloudDocs/vNote/学习/' -name '*.png' -print0 | xargs -0 -J % cp % /Users/jingtianyou/github/Jekyll-Pithy/images/
# 替换文本
grep -rl _v_images /Users/jingtianyou/github/Jekyll-Pithy/_raw/* | xargs sed -i "" 's/_v_images/\/images/g'

cd /Users/jingtianyou/github/Jekyll-Pithy/_raw/
tags_arr=("redis" "mysql" "tcp&ip" "shell" "os" "sysDesign" "pic")

for file in ./*
do
    # 判断是否更新
    new="yes"
    for file1 in /Users/jingtianyou/github/Jekyll-Pithy/_posts/*
    do
        fileExtName=`basename $file`
        fileName=${fileExtName%.*}
        if [[ $file1 =~ $fileExtName ]]; then
            oldHead=$(head -n 6 $file1)
            echo "$oldHead" > $file1
            cat $file >> $file1
            echo "更新"$file1
            new="no"
            break
        fi
    done
    if [ "$new" = "yes" ]; then
        if !(head -n 2 $file | grep -q 'layout'); then
            tags=" "
            for tag in ${tags_arr[@]}
            do
                if [[ $fileName =~ $tag ]]; then
                    tags=$tag
                fi
            done
            if [ "$tags" = " " ]; then
                tags="else"
            fi
            sed -i '' -e "1i \\
            --- \\
            layout: post \\
            title: ${fileName} \\
            date: $(date +'%Y-%m-%d %H:%M:%S') \\
            categories: ${tags} \\
            ---" $file
        fi
        cp $fileExtName /Users/jingtianyou/github/Jekyll-Pithy/_posts/$(date +'%Y-%m-%d-')$fileExtName
        echo "新增"$(date +'%Y-%m-%d-')$fileExtName
    fi
done

cd /Users/jingtianyou/github/Jekyll-Pithy/
git st
git add .
git ci -m 'update'
git push origin master
