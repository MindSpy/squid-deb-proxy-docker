ARG platform=$TARGETPLATFORM
FROM --platform=$platform debian:bullseye-slim

ARG USE_AVAHI=0
ARG PKG_PROXY

ENV USE_ACL=1 \
  USE_AVAHI=${USE_AVAHI}

RUN set -ex \
  ; export DEBIAN_FRONTEND=noninteractive \
  ; if [ -n "$PKG_PROXY" ]  \
  ; then echo "Acquire::http::Proxy \"$PKG_PROXY\";" >> /etc/apt/apt.conf.d/01proxybuild \
  ; fi \
  ; pkgs="ca-certificates squid-deb-proxy" \
  ; if [ "${USE_AVAHI}" = "1" ]  \
  ; then pkgs="$pkgs avahi-utils avahi-daemon squid-deb-proxy-client" \
  ; fi \
  ; apt-get update -y  \
  ; apt-get install -y --no-install-recommends --reinstall $pkgs  \
  ; update-ca-certificates \
  ; apt-get clean \
  ; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  ; rm /etc/apt/apt.conf.d/01proxybuild || true \
  ; env --unset=DEBIAN_FRONTEND 

# Add ACLs
COPY etc /etc

RUN set -ex \
  # extend config
  ; cat /etc/squid-deb-proxy/squid-deb-proxy.conf.add >> \
  /etc/squid-deb-proxy/squid-deb-proxy.conf \
  # Point cache directory to /data
  ; ln -sf /data /var/cache/squid-deb-proxy \
  # Redirect logs to stdout for the container
  ; ln -sf /dev/stdout /var/log/squid-deb-proxy/access.log \
  ; ln -sf /dev/stdout /var/log/squid-deb-proxy/store.log \
  ; ln -sf /dev/stdout /var/log/squid-deb-proxy/cache.log 

COPY docker-entrypoint.sh /docker-entrypoint.sh

VOLUME ["/data"]

EXPOSE 8000 5353/udp

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["squid"]
