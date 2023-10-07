# syntax=docker/dockerfile:1

FROM eclipse-temurin:17-alpine

LABEL maintainer="https://github.com/csferns/mcserver"

ARG USER=mcadmin
ARG GROUP=minecraft

RUN apk add --update --no-cache --no-progress tar curl jq

RUN mkdir -p /minecraft

RUN addgroup -S "$GROUP"
RUN adduser -G "$GROUP" -s /bin/sh -SDH "$USER"
RUN chown -R "$USER":"$GROUP" /minecraft

COPY scripts/*.sh /minecraft/

RUN (crontab -l ; echo "0 0 * * * /minecraft/backup.sh") | crontab -

USER "$USER"

VOLUME /minecraft
EXPOSE 25565/tcp 25565/udp

WORKDIR /minecraft

ENTRYPOINT [ "sh", "docker-entrypoint.sh" ]