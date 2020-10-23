# iPA RediSearch

This is a container image based on
[bitnami-docker-redis](https://github.com/bitnami/bitnami-docker-redis) with an
auto-updating script for the [IndicePA](https://www.indicepa.gov.it/) index of
Italian Public Administrations.

## Build

Supported args:

- `REDIS_VERSION` (mandatory - minimium version 5.0.9)
- `REDISEARCH_GITHUB_BRANCH` (mandatory - must be compatible with the configured Redis version)

## Run

Supported env variables:

- [env vars supported in
  bitnami-docker-redis](https://github.com/bitnami/bitnami-docker-redis#configuration)

*Do not use slashes (/) in REDIS_PASSWORD to not break the export of env
variabile into cron script*

## Usage

The index name is `IPAIndex` with the following text fields:

- `ipa_code` - weight: 2.0
- `name` - weight: 2.0 - sortable
- `site`
- `pec`
- `city` - weight: 1.4
- `county`
- `region`
- `type`
- `rtd_name`
- `rtd_pec`
- `rtd_mail`

Please refer to [RediSearch
Documentation](https://oss.redislabs.com/redisearch/index.html).
