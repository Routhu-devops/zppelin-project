FROM zeppelin/zeppelin
RUN mkdir -p /opt/deployment &&\
    mkdir -p /opt/zeppelin

#Copying tar.gz file from Jenkins buildVE to deployment path
COPY target/zeppelin-*-tar.gz /opt/deployment/
RUN tar xzvf /opt/deployment/zeppelin-*-tar.gz -C /opt/zeppelin/ \
&& rm -f /opt/zeppelin/zeppelin-*-tar.gz

#Link persistent files:
RUN ln -sf /opt/zeppelin/zeppelin-* /opt/zeppelin/spark-zeppelin
COPY scripts/* /opt/zeppelin/spark-zeppelin/
RUN chmod +x /opt/zeppelin/spark-zeppelin/bin/*.sh 
#/opt/zeppelin/spark-zeppelin/conf/*.sh

#RUN chown -R appuser:appuser /opt/
#USER appuser
#Starting zeppelin instance
CMD ["/bin/bash", "-c", "/opt/zeppelin/spark-zeppelin/bin/zeppelin-daemon.sh start; while true; do sleep 10; done"]
