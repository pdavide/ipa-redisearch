# iPA RediSearch

This is a container image based on
[bitnami-docker-redis](https://github.com/bitnami/bitnami-docker-redis) with an
auto-updating script for the [IndicePA](https://www.indicepa.gov.it/) index of
Italian Public Administrations.

## Build

Supported args:

- `REDIS_VERSION` (mandatory)
- `REDISEARCH_GITHUB_BRANCH` (mandatory)

## Run

Supported env variables:

- [env vars supported in
  bitnami-docker-redis](https://github.com/bitnami/bitnami-docker-redis#configuration)

## Usage

The index name is `IPAIndex` with the following text fields:

- `ipa_code` - weight: 2.0
- `name` - weight: 2.0
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
