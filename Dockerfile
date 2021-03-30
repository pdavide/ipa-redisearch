ARG REDIS_VERSION
ARG REDISEARCH_VERSION

FROM redislabs/redisearch:${REDISEARCH_VERSION} as builder

LABEL maintainer="Davide Porrovecchio <davide.porrovecchio@agid.gov.it>"

# Main image
FROM bitnami/redis:${REDIS_VERSION}

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

COPY --from=builder /usr/lib/redis/modules/redisearch.so "$LIBDIR"
COPY ./build_ipa_index.py /opt/
COPY ./supervisord.conf /etc/supervisord.conf

# change default entrypoint
RUN mv /run.sh /run-redis.sh
COPY ./run.sh /run.sh
COPY ./update-index.sh /update-index.sh

RUN /bin/echo -e "0 6 * * * root /update-index.sh > /proc/1/fd/1 2>/proc/1/fd/2\n" > /etc/cron.d/build_ipa_index
RUN chmod 644 /etc/cron.d/build_ipa_index && \
    chmod 544 /update-index.sh

ENTRYPOINT ["/run.sh"]
