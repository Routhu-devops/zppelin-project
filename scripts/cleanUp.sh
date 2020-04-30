#!/bin/bash

install_dir=$1
dir_pref=$2
num_to_keep=$3

echo ""
echo "Deleting builds older than $del_build_no from $install_dir:"
echo  ""
cd $install_dir
dirs_rem=$(ls -t | grep $dir_pref)
i=1

for oldDir in $dirs_rem; do
    if [ $i -gt $num_to_keep ]; then
       echo " cleaning up $oldDir"
       rm -Rf $oldDir
    fi
    i=$((i + 1))
done

echo ""
echo "Done"
echo ""
