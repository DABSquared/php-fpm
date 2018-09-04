#!/bin/bash
set -eo pipefail
shopt -s nullglob


if [ -f "/usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini" ]
then
    mv /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini /usr/local/etc/docker-php-ext-xdebug.ini
fi

mkdir -p var/cache var/logs temp/

rm -rf node_modules

if [ "$ISDEV" == "true" ]; then
   composer install --optimize-autoloader --no-interaction || (echo >&2 "Composer Install Dev Failed" && exit 1)
else
   composer install --optimize-autoloader --no-interaction --no-dev || (echo >&2 "Composer Install Prod Failed" && exit 1)
   composer dump-autoload --optimize --no-dev --classmap-authoritative || (echo >&2 "Composer AutoDump Prod Failed" && exit 1)
fi

if [ "$ISDEV" == "true" ]; then
   yarn install --dev
   yarn run encore dev
else
   yarn install
   yarn run encore production
fi

if [ "$ASSECTIC" == "true" ]; then
   php bin/console --env="$ENVIRONMENT" assets:install web
fi

if [ "$ASSECTIC" == "true" ]; then
	if [ "$ISDEV" == "true" ]; then
   		php bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction
	else
   		php bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction --no-debug
	fi
fi

chmod -R 777 var/cache
chmod -R 777 var/logs
chmod -R 777 temp
chmod -R 777 src/

if [ -f "/usr/local/etc/docker-php-ext-xdebug.ini" ]
then
    mv /usr/local/etc/docker-php-ext-xdebug.ini /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini
fi
