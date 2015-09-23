FROM debian:jessie
MAINTAINER fzerorubigd <fzero@rubi.gd> @fzerorubigd

RUN apt-get update && apt-get install -y --no-install-recommends \
		wget \
	&& rm -rf /var/lib/apt/lists/*

RUN wget --quiet --no-check-certificate -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update

RUN apt-get update && apt-get install -y --no-install-recommends \
		pgbouncer \
	&& rm -rf /var/lib/apt/lists/*

ADD docker-initscript.sh /sbin/docker-initscript.sh
RUN chmod 755 /sbin/docker-initscript.sh
EXPOSE 5432/tcp
CMD ["/sbin/docker-initscript.sh"]
