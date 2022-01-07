#

ARG platform=linux/amd64
FROM --platform=${platform} debian:bullseye-slim
MAINTAINER https://github.com/muccg/

ARG USE_AVAHI=0

ENV USE_ACL=1 \
    USE_AVAHI=${USE_AVAHI}

RUN set -ex \
  ; export DEBIAN_FRONTEND=noninteractive \
  ; pkgs=squid-deb-proxy \
  ; if [ "${USE_AVAHI}" = "1" ]; then  \
    pkgs="$pkgs avahi-utils avahi-daemon squid-deb-proxy-client" \
  ; fi \
  ; apt-get update -y  \
  ; apt-get install -y --no-install-recommends --reinstall \
    $pkgs ca-certificates \
  ; update-ca-certificates \
  ; apt-get clean \
  ; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
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
