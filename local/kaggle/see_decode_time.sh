#!/bin/bash
test_dir=$1
for dir in $test_dir/* ; do
  if [ -d $dir ] && [ -f $dir/3small_time ] && [ -f $dir/rescore_time ] ; then
    echo $dir 
    cat $dir/3small_time
    cat $dir/rescore_time
    du -sh $dir/decode*/lat*
    cat $dir/rescore_lang
    echo " "
    echo "-------------------------------"
  fi
done
