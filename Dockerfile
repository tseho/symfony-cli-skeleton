FROM php:8.0.13-cli AS core

RUN apt-get update \
    && apt-get install -y \
        libicu-dev \
        libonig-dev \
    && docker-php-ext-install \
        bcmath \
        intl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY ./docker/php/php.ini /usr/local/etc/php/conf.d/000-docker.ini

###############################################################################

FROM core AS composer

ENV COMPOSER_HOME=/tmp

RUN apt-get update \
    && apt-get install -y \
        git \
        unzip \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=composer:2.1.12 /usr/bin/composer /usr/bin/composer
COPY ./docker/composer/php.ini /usr/local/etc/php/conf.d/custom.ini

ENTRYPOINT ["composer"]
CMD ["help"]

###############################################################################

FROM core AS runtime

ARG BUILD_ENV=prod
ARG APP_ENV=prod
ARG USER=www-data

RUN if [ "$BUILD_ENV" = "dev" ] || [ "$BUILD_ENV" = "test" ]; then \
    pecl install \
        xdebug \
        pcov && \
    docker-php-ext-enable \
        xdebug \
        pcov \
    ; fi

RUN mkdir -p /srv/app && chown $USER /srv/app
WORKDIR /srv/app

ENV APP_ENV=$APP_ENV
USER $USER

###############################################################################

FROM composer AS vendors

ARG BUILD_ENV=prod
ARG USER=www-data

RUN mkdir -p /srv/app/vendor && chown -R $USER /srv/app
WORKDIR /srv/app
COPY composer.json composer.lock symfony.lock ./

RUN if [ "$BUILD_ENV" = "prod" ]; then export COMPOSER_ARGS=--no-dev; fi; \
    composer install \
        --no-scripts \
        --no-interaction \
        --no-ansi \
        --prefer-dist \
        --optimize-autoloader \
        ${COMPOSER_ARGS}

###############################################################################

FROM runtime AS cli

COPY . .
COPY --from=vendors /srv/app/vendor vendor

RUN cp -n .env.dist .env \
    && php bin/console cache:warmup

CMD ["php", "-a"]
