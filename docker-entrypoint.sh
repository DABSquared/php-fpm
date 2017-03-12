#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [ "$1" = 'php-fpm' ]; then
    mkdir -p var/cache var/logs temp/

    #TODO: Template the parameters file here...
    
    #Save off the db dir number.
    numdirs=$(ls -l "$DB_DIR" | grep -v ^d | wc -l | xargs)
    echo "Number of db directories is $numdirs"


    if [ "$ISDEV" == "true" ]; then
       composer install --optimize-autoloader --no-interaction || (echo >&2 "Composer Install Failed" && exit 1)
    else
       composer install --optimize-autoloader --no-interaction --no-dev || (echo >&2 "Composer Install Failed" && exit 1)
    fi

    php bin/console --env="$ENVIRONMENT" doctrine:migrations:migrate --no-interaction || (echo >&2 "Doctrine Migrations Failed" && exit 1)
    php bin/console --env="$ENVIRONMENT" assets:install web || (echo >&2 "Assetic Install Failed" && exit 1)

    if [ "$ISDEV" == "true" ]; then
        php bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction || (echo >&2 "Assetic Dump Failed" && exit 1)
    else
        php bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction --no-debug || (echo >&2 "Assetic Dump Failed" && exit 1)
    fi

    if [ "$ISDEV" == "true" ]; then
        php bin/console --env="$ENVIRONMENT" cache:warmup || (echo >&2 "Cache Warmup Failed" && exit 1)
    else
        php bin/console --env="$ENVIRONMENT" cache:warmup --no-debug || (echo >&2 "Cache Warmup Failed" && exit 1)
    fi

    if [ "$ISDEV" == "true" ]; then
            if  [ $numdirs -le 2 ]; then
                php bin/console --env="$ENVIRONMENT" doctrine:fixtures:load --no-interaction --multiple-transactions || (echo >&2 "Doctrine Fixtures Failed" && exit 1)
            fi
    fi
fi

exec "$@"
