FROM redislabs/redisearch:latest

LABEL maintainer="Davide Porrovecchio <davide.porrovecchio@agid.gov.it>"

ENV DEBIAN_FRONTEND noninteractive

ENV TZ Europe/Rome
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get update && apt-get install -y --no-install-recommends \
    supervisor \
    cron \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-wheel \
 && rm -rf /var/lib/apt/lists/*
RUN pip3 install pandas redisearch

COPY ./build_ipa_index.py /opt/
COPY ./supervisord.conf /etc/supervisord.conf

RUN echo "0 6 * * * root /usr/bin/python3 /opt/build_ipa_index.py >/dev/null 2>&1" > /etc/cron.d/build_ipa_index
RUN chmod 644 /etc/cron.d/build_ipa_index

CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisord.conf"]