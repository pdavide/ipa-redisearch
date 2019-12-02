ARG REDIS_VERSION
FROM docker.io/bitnami/redis:${REDIS_VERSION} as builder

LABEL maintainer="Davide Porrovecchio <davide.porrovecchio@agid.gov.it>"

ENV DEBIAN_FRONTEND noninteractive

ARG REDISEARCH_GITHUB_BRANCH

# Build redis-search module
USER root

RUN apt-get update && apt-get install -y git automake build-essential cmake && \
  mkdir /build && cd ~/build && \
  git clone --branch ${REDISEARCH_GITHUB_BRANCH} https://github.com/RedisLabsModules/RediSearch.git && \
  cd RediSearch && \
  make all && \
  rm -rf /var/lib/apt/lists/* 

# Main image
FROM docker.io/bitnami/redis:${REDIS_VERSION}

USER 0

# Set the timezone
ENV TZ Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    cron \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install pandas redisearch

ENV LIBDIR /opt/bitnami/redis/bin
WORKDIR /data

COPY --from=builder /build/RediSearch/src/redisearch.so  "$LIBDIR"
COPY ./build_ipa_index.py /opt/
COPY ./supervisord.conf /etc/supervisord.conf

RUN echo "0 6 * * * root /usr/bin/python3 /opt/build_ipa_index.py >/dev/null 2>&1" > /etc/cron.d/build_ipa_index
RUN chmod 644 /etc/cron.d/build_ipa_index

ENTRYPOINT ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]
