#!/bin/bash
set -eo pipefail
shopt -s nullglob

cd /var/www/symfony

mkdir -p var/cache var/logs temp/

echo "parameters:" > app/config/parameters.yml
echo "parameters:" > app/config/parameters.yml.dist

while IFS='=' read -r envvar_key envvar_value
do
    if [[ "$envvar_key" =~ ^[symfony]+\_[a-z]+ ]]
    then
          replaceWith=""
          envvar_key=${envvar_key/symfony_/${replaceWith}}

          if [ "$envvar_value" == "true" ] || [ "$envvar_value" == "false" ]
          then
              echo "    $envvar_key: $envvar_value" >> app/config/parameters.yml
              echo "    $envvar_key: $envvar_value" >> app/config/parameters.yml.dist
          else
              echo "    $envvar_key: '$envvar_value'" >> app/config/parameters.yml
              echo "    $envvar_key: '$envvar_value'" >> app/config/parameters.yml.dist
          fi


    fi
done < <(env)

bundle install --binstubs --no-cache
rm -rf node_modules



if [ "$ISDEV" == "true" ]; then
   yarn install --dev
   yarn run encore dev
else
   yarn install
   yarn run encore prodution
fi

if [ "$ISDEV" == "true" ]; then
   composer install --optimize-autoloader --no-interaction || (echo >&2 "Composer Install Dev Failed" && exit 1)
else
   composer install --optimize-autoloader --no-interaction --no-dev || (echo >&2 "Composer Install Prod Failed" && exit 1)
fi

php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" doctrine:migrations:migrate --no-interaction || (echo >&2 "Doctrine Migrations Failed" && exit 1)
php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" assets:install web || (echo >&2 "Assetic Install Failed" && exit 1)

 if [ "$ISDEV" == "true" ]; then
     php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction || (echo >&2 "Assetic Dump Dev Failed" && exit 1)
 else
     php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction --no-debug || (echo >&2 "Assetic Dump Prod Failed" && exit 1)
 fi

if [ "$ISDEV" == "true" ]; then
    php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" cache:warmup || (echo >&2 "Cache Warmup Dev Failed" && exit 1)
else
    php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" cache:warmup --no-debug || (echo >&2 "Cache Warmup Prod Failed" && exit 1)
fi

chmod -R 777 var/cache
chmod -R 777 var/logs
chmod -R 777 temp
chmod -R 777 src/
