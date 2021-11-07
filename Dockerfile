FROM php:8-apache AS runtime

ARG BUILD_ENV=prod
ARG USER=www-data

RUN apt-get update \
    && apt-get install -y \
        libicu-dev \
        libonig-dev \
    && docker-php-ext-install \
        bcmath \
        intl \
    && mv /etc/apache2/mods-available/rewrite.load /etc/apache2/mods-enabled/rewrite.load \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN if [ "$BUILD_ENV" = "dev" ] || [ "$BUILD_ENV" = "test" ]; then \
    pecl install \
        xdebug \
        pcov && \
    docker-php-ext-enable \
        xdebug \
        pcov \
    ; fi

RUN mkdir /srv/app && chown $USER /srv/app
WORKDIR /srv/app

###############################################################################

FROM runtime AS composer

ENV COMPOSER_HOME=/tmp

RUN apt-get update \
    && apt-get install -y \
        git \
        unzip \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --from=composer:2.1 /usr/bin/composer /usr/bin/composer
COPY ./docker/composer/php.ini /usr/local/etc/php/conf.d/custom.ini

ENTRYPOINT ["composer"]
CMD ["help"]

###############################################################################

FROM composer AS vendors

ARG BUILD_ENV=prod

WORKDIR /srv/app
RUN mkdir /srv/app/vendor
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

ARG USER=www-data
ARG APP_ENV=prod

ENV APP_ENV=$APP_ENV

WORKDIR /srv/app

USER $USER

COPY . .
COPY --from=vendors /srv/app/vendor vendor

RUN cp -n .env.dist .env \
    && php bin/console cache:warmup

CMD ["php", "-a"]
