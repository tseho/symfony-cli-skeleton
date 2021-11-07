# Symfony CLI Skeleton

## How to use the skeleton

```shell
composer create-project tseho/symfony-cli-skeleton [directory]
```

## Production

Build the docker image:
```shell
DOCKER_IMAGE_NAME=foo DOCKER_IMAGE_VERSION=latest make docker-image
```

Launch a symfony command with it:
```shell
docker run --rm $DOCKER_IMAGE_NAME:$DOCKER_IMAGE_VERSION bin/console [cmd]
```

## Development

Build the development environment:
```shell
make build
```
How to execute a symfony command:
```shell
docker-compose run --rm php bin/console [cmd]
```
How to execute a composer command:
```shell
docker-compose run --rm composer [cmd]
```
How to launch the tests:
```shell
make tests
```
