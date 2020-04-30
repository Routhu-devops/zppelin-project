#!/bin/bash
#set -x
cd /opt/zeppelin/spark-zeppelin/custom-lib
for eachjar in $(ls *.jar); do echo `pwd`/$eachjar; done | tr '\n' ','| sed 's/,*$//g' > /opt/zeppelin/spark-zeppelin/conf/alljars
cd /opt/zeppelin/spark-zeppelin/conf
oldjars=$(cat veeru.json | grep -A3 spark.jars | tr , '\n' | grep value | cut -d : -f2 | uniq)
newjars=$(cat /opt/zeppelin/spark-zeppelin/conf/alljars)
if [[ "$oldjars" == "$newjars" ]]; then
  echo "interpreter.json is up-to-date with spark jars"
else
  cp interpreter.json interpreter.json_bkp
  oldjars_esc=$(sed 's/[]\/$*.^[]/\\&/g' <<<"$oldjars")
  newjars_esc=$(sed 's/[]\/$*.^[]/\\&/g' <<<"$newjars")
  sed -i "s/$oldjars_esc/$newjars_esc/g" interpreter.json
fi
