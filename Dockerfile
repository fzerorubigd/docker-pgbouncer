FROM alpine:3.3

MAINTAINER fzerorubigd <fzero@rubi.gd> @fzerorubigd

RUN apk update && \
	apk add alpine-sdk openssl-dev libwebsockets-dev c-ares-dev libevent-dev autoconf automake libtool && \
	git clone --recursive https://github.com/pgbouncer/pgbouncer.git  && \
	cd pgbouncer && git checkout pgbouncer_1_7 && \
	./autogen.sh && \
	./configure && \
	make && \
	make install && \
	apk del alpine-sdk autoconf automake libtool && \
	cd / && \
	rm -rf /pgbouncer 

ADD docker-initscript.sh /sbin/docker-initscript.sh
RUN chmod 755 /sbin/docker-initscript.sh
EXPOSE 5432/tcp
ENTRYPOINT ["/sbin/docker-initscript.sh"]
CMD ["pgbouncer"]