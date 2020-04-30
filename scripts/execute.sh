#!/bin/bash
if [ $# -lt 8 ]; then
    echo "You must provide these parameters:"
    echo "   Jenkins build number"
    echo "   Number builds to keep (not delete) on target VE"
    echo "   VE host name where to deploy Zeppelin"
    echo "   Host name (could be localhost) of source project"
    echo "   Project path, which must contain flow directory"
    echo "   Pre-existing Zeppelin tar.gz file"
    echo "   Zeppelin installation directory"
    echo "   Zeppelin build directories prefix"
    exit 1
fi

BUILD_NUMBER=$1
NUM_TO_KEEP=$2
VE_HOST=$3
APP_HOST=$4
INST_PATH=$5
ZEP_PATH=$6
INSTALL_DIR=$7
DIR_PREF=$8
#FLOW_HDFS_PATH=$9
#PKG_RELEASE_VERSION=$10

echo "BUILD_NUMBER=$BUILD_NUMBER"
echo "NUM_TO_KEEP=$NUM_TO_KEEP"
echo "VE_HOST=$VE_HOST"
echo "APP_HOST=$APP_HOST"
echo "INST_PATH=$INST_PATH"
echo "ZEP_PATH=$ZEP_PATH"
echo "INSTALL_DIR=$INSTALL_DIR"
echo "DIR_PREF=$DIR_PREF"
#echo "FLOW_HDFS_PATH=$FLOW_HDFS_PATH"
#echo "PKG_RELEASE_VERSION=$PKG_RELEASE_VERSION"

#This is the only script executed from JENKINS job

echo "Will cleanup builds older than `expr $BUILD_NUMBER - $NUM_TO_KEEP` from $VE_HOST"

# first deploy the scripts to target VE
ssh username@$VE_HOST "mkdir -p /opt/autobuilds/test_$BUILD_NUMBER/"
rsync -ar --exclude '.git' --exclude 'tests/' * username@$VE_HOST:/opt/autobuilds/test_$BUILD_NUMBER/

# update test files with files substituted by Maven with build variables
rsync -ar target/classes/ username@$VE_HOST:/opt/autobuilds/test_$BUILD_NUMBER/tests/

# clean up old test builds
ssh username@$VE_HOST "cd /opt/autobuilds/test_$BUILD_NUMBER/; sh -x ./scripts/cleanUp.sh $INSTALL_DIR $DIR_PREF $NUM_TO_KEEP"

# next, deploy Project and configure Zeppelin
ssh username@$VE_HOST "cd /opt/autobuilds/test_$BUILD_NUMBER/; sh -x ./scripts/clone.sh $APP_HOST $INST_PATH /home/ciq/spark/zeppelin-0.7.3-iqi.tar.gz"
ssh username@$VE_HOST "cd /opt/autobuilds/test_$BUILD_NUMBER/; sh -x ./scripts/importNote.sh /opt/autobuilds/test_$BUILD_NUMBER/tests/sparkTest.json http://$VE_HOST:8080"
ssh username@$VE_HOST "cd /opt/autobuilds/test_$BUILD_NUMBER/; sh -x ./scripts/runNote.sh /opt/autobuilds/test_$BUILD_NUMBER/import.log http://$VE_HOST:8080 30"
ssh username@$VE_HOST "cd /opt/autobuilds/test_$BUILD_NUMBER/; python scripts/update_notebook_vars.py /opt/autobuilds/test_$BUILD_NUMBER/tests/sparkTest.json /opt/autobuilds/test_$BUILD_NUMBER/outputvalidation $FLOW_HDFS_PATH $PKG_RELEASE_VERSION"

if [ $? -ne 0 ]; then
    echo "Executing test notebook failed"
    exit 1
fi
mkdir -p logs

# save results file
scp username@$VE_HOST:/opt/autobuilds/test_$BUILD_NUMBER/logs/* logs/
