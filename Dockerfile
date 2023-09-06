FROM alpine:3.17.2 AS build

RUN apk add -u tzdata ca-certificates build-base gcc curl openssl-dev zlib-dev
RUN apk add pcre-dev perl linux-headers

WORKDIR /
RUN curl -O https://netxms.org/download/releases/4.4/netxms-4.4.2.tar.gz
RUN tar -xzf netxms-4.4.2.tar.gz
WORKDIR /netxms-4.4.2
RUN ./configure --prefix=/netxms --with-agent
RUN make install
RUN rm -rf /netxms/bin/nx-run-asan-binary /netxms/bin/nxagentd-asan /netxms/bin/nxdevcfg /netxms/include /netxms/share

FROM alpine:3.17.2

ENV TZ=Europe/Riga

RUN \
   apk add --no-cache --update su-exec dumb-init ca-certificates libpcre32 libssl3 libstdc++ pcre tzdata zlib && \
   addgroup -S netxms && adduser -S -G netxms netxms && \
   mkdir -p /netxms/var/lib/netxms && chown -R netxms. /netxms/var/lib/netxms && \
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
