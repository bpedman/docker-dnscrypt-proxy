FROM alpine as builder

ARG OS=linux
ARG ARCH=x86_64
ARG VERSION=2.0.25
ARG SHA256SUM=9c08f76437c3efaea49b5787cfb24a1680666275c4e2103b5531a63b5c0fe0dd

RUN apk add curl ca-certificates

RUN curl -fLsS -o dnscrypt-proxy.tar.gz https://github.com/jedisct1/dnscrypt-proxy/releases/download/${VERSION}/dnscrypt-proxy-${OS}_${ARCH}-${VERSION}.tar.gz && \
    sum=$(sha256sum -b dnscrypt-proxy.tar.gz | awk '{ print $1 }') && \
    if [ "${sum}" != "${SHA256SUM}" ]; then \
        echo "expected sum ${SHA256SUM} does not match downloaded file sum ${sum}"; \
        exit 1; \
    fi && \
    tar -xzvf dnscrypt-proxy.tar.gz && \
    mv ${OS}-${ARCH} dnscrypt-proxy

FROM scratch
LABEL maintainer="Brandon Pedersen <bpedman@gmail.com>" \
      description="A flexible DNS proxy, with support for modern encrypted DNS protocols \
                  such as DNSCrypt v2 and DNS-over-HTTP/2." \
      url="https://github.com/jedisct1/dnscrypt-proxy"

# Environmet
ENV TZ America/Denver

# publish port DNS over UDP & TCP
EXPOSE 53/TCP 53/UDP

# service running
STOPSIGNAL SIGTERM

# command
CMD [ "dnscrypt-proxy", "-config", "/etc/dnscrypt-proxy/example-dnscrypt-proxy.toml"]

# Multi stage build
WORKDIR /etc/dnscrypt-proxy/
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /dnscrypt-proxy/dnscrypt-proxy /usr/local/bin/
COPY --from=builder /dnscrypt-proxy/example-* /etc/dnscrypt-proxy/
