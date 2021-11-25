#!/bin/bash


path=$1
files=$(find $path -name "*.md")
for filename in $files
do
	gsed -i '/^layout/d' $filename
	gsed -i '/^date/d' $filename
	gsed -i '/^key/d' $filename

	date=${filename:3:10}
	gsed -i "/^title/a\date: ${date}" $filename
	gsed -i 's/tags: /tags: \n- /' $filename
	mv $filename ${filename:14}
done
