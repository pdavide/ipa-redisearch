ARG REDIS_VERSION
FROM docker.io/bitnami/redis:${REDIS_VERSION} as builder

LABEL maintainer="Davide Porrovecchio <davide.porrovecchio@agid.gov.it>"

ENV DEBIAN_FRONTEND noninteractive

ARG REDISEARCH_GITHUB_BRANCH

# Build redis-search module
USER root

RUN apt-get update && apt-get install -y git && \
    mkdir -p /build-redisearch && cd ~/build-redisearch && \
    git clone --branch ${REDISEARCH_GITHUB_BRANCH} --recursive https://github.com/RedisLabsModules/RediSearch.git && \
    cd RediSearch && \
    ./deps/readies/bin/getpy2 && \
    ./system-setup.py && \
    make fetch && \
    make build && \
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

COPY --from=builder /build-redisearch/RediSearch/src/redisearch.so "$LIBDIR"
COPY ./build_ipa_index.py /opt/
COPY ./supervisord.conf /etc/supervisord.conf

# change default entrypoint
RUN mv /run.sh /run-redis.sh
COPY ./run.sh /run.sh

RUN echo "0 6 * * * root /usr/bin/python3 /opt/build_ipa_index.py >/dev/null 2>&1" > /etc/cron.d/build_ipa_index
RUN chmod 644 /etc/cron.d/build_ipa_index

ENTRYPOINT ["/run.sh"]
