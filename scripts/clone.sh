#!/bin/bash
if [ $# -lt 3 ]; then
	echo "You must provide these parameters:"
	echo "   Host name (could be localhost) of source project"
	echo "   Project path, which must contain flow directory"
	echo "   Pre-existing Zeppelin tar.gz file"
	exit 1
fi

VE=$1
PATH=$2
ZEP_PATH=$3

echo "Verifying $PATH on $VE"
ssh $VE "ls $PATH/flow"
if [ $? -ne 0 ]; then
    echo "ERROR! Package offering $PATH does not exist on $VE!"
    exit 1
fi

if [ ! -f $ZEP_PATH ]; then
    echo "ERROR! Zeppelin $ZEP_PATH does not exist!"
    exit 1
fi

echo "Cloning Zeppelin from $ZEP_PATH into `pwd`"
#rsync -ar --exclude 'metastore_db' $ZEP_PATH .
tar xzf $ZEP_PATH 
if [ $? -ne 0 ]; then
    echo "ERROR: failed to install Zeppelin from $ZEP_PATH"
    exit 1
fi

echo "Setting up Zeppelin with Custom files from $PATH"
rsync -ar username@$VE:$PATH/flow/Libs/* zeppelin-0.7.3/custom_lib/
if [ $? -ne 0 ]; then
    echo "ERROR: failed to setup Zeppelin libs,"
    echo "   into $ZEP_PATH/custom_lib "
    echo "   from $PATH/Libs"
    exit 1
fi

