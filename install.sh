#!/bin/sh
set -x
if [ $# -lt 2 ]; then
    echo "$0 requires min 2 parameters: "
    echo "   DEPLOY_VE"
    echo "   DEPLOY_DIR"
    echo "And this parameter is optional"
    echo "   ZEP_USER"
    exit 1
fi

DEPLOY_VE=$1
DEPLOY_DIR=$2
if [ $# -eq 3 ]; then
    ZEP_USER=$3
else
    ZEP_USER="hadoop"
fi

echo "Deploying Zeppelin $BUILD_VER to $DEPLOY_VE in $DEPLOY_DIR/"

ssh $ZEP_USER@$DEPLOY_VE "mkdir -p $DEPLOY_DIR"
if [ $? -ne 0 ]; then
    echo "Failed to create remote dir $ZEP_USER@$DEPLOY_VE:$DEPLOY_DIR"
    exit 1
fi

echo "Uploading Zeppelin $BUILD_VER files"
scp target/zeppelin-$BUILD_VER-tar.gz $ZEP_USER@$DEPLOY_VE:$DEPLOY_DIR/
if [ $? -ne 0 ]; then
    echo "Failed to upload file target/zeppelin-$BUILD_VER.tar.gz to $ZEP_USER@$DEPLOY_VE/$DEPLOY_DIR"
    exit 1
fi
ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR/; tar xzf zeppelin-$BUILD_VER.tar.gz"
if [ $? -ne 0 ]; then
    echo "Failed to extract file zeppelin-$BUILD_VER to $ZEP_USER@$DEPLOY_VE/$DEPLOY_DIR"
    exit 1
fi
#check if we need to deploy on-demand
#if [ -f target/zeppelin-$BUILD_VER.tar.gz ]; then
#    echo "Uploading Custom Jars on-demand servers for Zeppelin"
#    scp target/zeppelin-$BUILD_VER.tar.gz $ZEP_USER@$DEPLOY_VE:$DEPLOY_DIR/zeppelin-$BUILD_VER/custom-lib/
#    if [ $? -ne 0 ]; then
#        echo "Failed to upload file target/zeppelin-$BUILD_VER to $ZEP_USER@$DEPLOY_VE/$DEPLOY_DIR/zeppelin-$BUILD_VER/custom-lib/"
#        exit 1
#    fi
#
#    ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR/zeppelin-$BUILD_VER; tar xzf zeppelin-$BUILD_VER.tar.gz"
#    if [ $? -ne 0 ]; then
#        echo "Failed to extract file zeppelin-$BUILD_VER to $ZEP_USER@$DEPLOY_VE/$DEPLOY_DIR/zeppelin-$BUILD_VER/custom-lib/"
#        exit 1
#    fi
#
#    ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR/zeppelin-$BUILD_VER; tar xzf zeppelin-$BUILD_VER.tar.gz"
#    if [ $? -ne 0 ]; then
#        echo "Failed to extract file zeppelin-$BUILD_VER to $ZEP_USER@$DEPLOY_VE/$DEPLOY_DIR/zeppelin-$BUILD_VER/custom-lib/"
#        exit 1
#    fi
#fi
ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR/; rm -f spark-zeppelin; ln -s zeppelin-$BUILD_VER spark-zeppelin"
if [ $? -ne 0 ]; then
    echo "Softlink creation is failed"
    exit 1
fi

echo "Check if zeppelin is running"
ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR; pgrep -f ZeppelinServer"

echo "kill the zeppelin process"
ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR; pkill -9 -f ZeppelinServer"

echo "Restarting Zeppelin."
ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR/zeppelin-$BUILD_VER/; sh ./bin/zeppelin-daemon.sh start"
if [ $? -ne 0 ]; then
    echo "ERROR: Zeppelin cannot be started"
	exit 1
fi
sleep 10

echo "Zeppelin server is running <a href="http://$DEPLOY_VE:8080/">here</a>"

ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR/zeppelin-$BUILD_VER/; sh -x ./testScripts/importNote.sh ./testScripts/resources/MeasureAgentBeanLoaderExamples.json $DEPLOY_VE"
if [ $? -ne 0 ]; then
    echo "ERROR: Paragraph failed with status ERROR"
        exit 0
fi
# Adding Authentication for users with enbling shiro.ini
ssh $ZEP_USER@$DEPLOY_VE "cd /opt/; sh cp /opt/zeppelin-conf/* /opt/zeppelin/spark-zeppelin/conf/"
if [ $? -ne 0 ]; then
    echo "No such file shiro.ini"
        exit 1
fi
echo "Check if zeppelin is running"
ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR; pgrep -f ZeppelinServer"

echo "kill the zeppelin process"
ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR; pkill -9 -f ZeppelinServer"

echo "Restarting Zeppelin."
ssh $ZEP_USER@$DEPLOY_VE "cd $DEPLOY_DIR/zeppelin-$BUILD_VER/; sh ./bin/zeppelin-daemon.sh start"
if [ $? -ne 0 ]; then
    echo "ERROR: Zeppelin cannot be started"
        exit 1
fi
