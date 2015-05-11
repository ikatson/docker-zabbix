FROM ubuntu:14.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y zabbix-server-pgsql postgresql-client python

EXPOSE 10051

ADD start.sh /start.sh

ENTRYPOINT ["/start.sh"]
