FROM alpine:3.21.3 AS build

RUN apk add -u tzdata ca-certificates build-base gcc curl openssl-dev zlib-dev
RUN apk add curl-dev expat-dev libssh-dev mosquitto-dev sqlite-dev pcre-dev jansson-dev perl linux-headers

WORKDIR /
RUN curl -O https://netxms.org/download/releases/5.1/netxms-5.1.4.tar.gz
RUN tar -xzf netxms-5.1.4.tar.gz
WORKDIR /netxms-5.1.4
RUN ./configure --prefix=/netxms --with-agent
RUN make -j $(nproc) install
RUN rm -rf /netxms/bin/nx-run-asan-binary /netxms/bin/nxagentd-asan /netxms/bin/nxdevcfg /netxms/include /netxms/share

FROM alpine:3.21.3

ENV TZ=Europe/Riga

RUN \
   apk add --no-cache --update su-exec dumb-init ca-certificates jansson libcurl libexpat libpcre32 libssh libssl3 libstdc++ mosquitto-libs pcre sqlite tzdata zlib && \
   addgroup -S netxms && adduser -S -G netxms netxms && \
   mkdir -p /netxms/var/lib/netxms && chown -R netxms /netxms/var/lib/netxms && \
   ln -s /usr/share/zoneinfo/${TZ} /etc/localtime && \
   echo "${TZ}" > /etc/timezone && date && \
   rm -rf /var/cache/apk/*

COPY --from=build /netxms /netxms
COPY --chmod=0555 init.sh /

VOLUME /netxms/etc
VOLUME /netxms/var/lib/netxms

EXPOSE 4700

USER netxms

ENTRYPOINT ["/init.sh"]
CMD ["/netxms/bin/nxagentd", "-f"]
