#!/bin/bash
set -e

if [ "$1" = 'php-fpm' ]; then
    mkdir -p var/cache var/logs temp/

    #TODO: Template the parameters file here...


    if [ "$ISDEV" == "true" ]; then
       composer install --optimize-autoloader --no-interaction
    else
       composer install --optimize-autoloader --no-interaction --no-dev
    fi

    #TODO: WAIT FOR DATABASE
    php bin/console --env="$ENVIRONMENT" doctrine:migrations:migrate --no-interaction
    php bin/console --env="$ENVIRONMENT" assets:install web

    if [ "$ISDEV" == "true" ]; then
        php bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction
    else
        php bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction --no-debug
    fi

    if [ "$ISDEV" == "true" ]; then
        php bin/console --env="$ENVIRONMENT" cache:warmup
    else
        php bin/console --env="$ENVIRONMENT" cache:warmup --no-debug
    fi

    if [ "$ISDEV" == "true" ]; then
        php bin/console --env="$ENVIRONMENT" doctrine:fixtures:load --no-interaction --multiple-transactions || exit 0
    fi
fi

exec "$@"
