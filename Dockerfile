FROM anapsix/alpine-java

ARG kafka_version=1.1.1
ARG scala_version=2.12


RUN apk add --update unzip wget curl docker jq coreutils

ENV KAFKA_VERSION=$kafka_version SCALA_VERSION=$scala_version
ADD kafkadocker/download-kafka.sh /tmp/download-kafka.sh
ADD kafkadocker/kafka_server_jaas.conf /tmp/kafka_server_jaas.conf
ADD kafkadocker/org.onap.dmaap.mr.trust.jks /tmp/org.onap.dmaap.mr.trust.jks
ADD kafkadocker/org.onap.dmaap.mr.p12 /tmp/org.onap.dmaap.mr.p12
ADD kafkadocker/org.onap.dmaap.mr.keyfile /tmp/org.onap.dmaap.mr.keyfile
ADD kafkadocker/cadi.properties /tmp/cadi.properties
ADD kafkadocker/mmagent.config /opt/etc/mmagent.config
ADD kafkadocker/consumer.properties /opt/etc/consumer.properties
ADD kafkadocker/producer.properties /opt/etc/producer.properties
ADD kafkadocker/kafka11aaf-jar-with-dependencies.jar /tmp/kafka11aaf-jar-with-dependencies.jar
ADD kafkadocker/dmaapMMAgent.jar /tmp/dmaapMMAgent.jar
ADD kafkadocker/kafka-run-class.sh /tmp/kafka-run-class.sh

RUN chmod a+x /tmp/download-kafka.sh && sync && /tmp/download-kafka.sh && tar xfz /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt && rm /tmp/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka

VOLUME ["/kafka"]

ENV KAFKA_HOME /opt/kafka
ENV PATH ${PATH}:${KAFKA_HOME}/bin
ADD kafkadocker/start-kafka.sh /usr/bin/start-kafka.sh
ADD kafkadocker/broker-list.sh /usr/bin/broker-list.sh
ADD kafkadocker/create-topics.sh /usr/bin/create-topics.sh
ADD kafkadocker/start-kafkaOrMirrorMaker.sh /usr/bin/start-kafkaOrMirrorMaker.sh
ADD kafkadocker/start-mirrormaker.sh /usr/bin/start-mirrormaker.sh
RUN mkdir /opt/logs
RUN touch /opt/logs/mmagent.log
# The scripts need to have executable permission
RUN chmod a+x /usr/bin/start-kafka.sh && \
    chmod a+x /usr/bin/broker-list.sh && \
    chmod a+x /usr/bin/start-kafkaOrMirrorMaker.sh && \
    chmod a+x /usr/bin/start-mirrormaker.sh && \
    chmod a+x /usr/bin/create-topics.sh
# Use "exec" form so that it runs as PID 1 (useful for graceful shutdown)
CMD ["start-kafkaOrMirrorMaker.sh"]

RUN addgroup -S -g 1000  mrkafka  \
    && adduser -S  -u 1000 mrkafka  mrkafka \
    && chown -R mrkafka:mrkafka  /opt/kafka/ /opt/logs/ /opt/etc/ /kafka/  /usr/bin/ /tmp/

USER mrkafka