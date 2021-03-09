#!/bin/bash
file_path=$1
src=$2
dst=$3
cd $file_path 
find -name "*$src*" | xargs rename $src $dst
grep -Ril $src * | xargs sed -i "s/$src/$dst/g"
typeset -u src_block
typeset -u dst_block
dst_block=$dst
src_block=$src
grep -Ril $src_block * | xargs sed -i "s/$src_block/$dst_block/g"
