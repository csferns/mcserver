FROM ubuntu:latest
ENV JAVA_HOME=/opt/java/openjdk
COPY --from=eclipse-temurin:17 $JAVA_HOME $JAVA_HOME
ENV PATH="${JAVA_HOME}/bin:${PATH}"

RUN apt-get update -y && apt-get upgrade -y
RUN apt-get install curl jq -y

RUN useradd -ms /bin/bash mcadmin
USER mcadmin

WORKDIR /opt/mcserver
COPY mcstart.sh /scripts/mcstart.sh

RUN mkdir server

ENTRYPOINT /scripts/mcstart.sh 'server'

EXPOSE 25565/tcp
EXPOSE 25565/udp