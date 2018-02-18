#!/bin/bash
set -eo pipefail
shopt -s nullglob

mkdir -p var/cache var/logs temp/

bundle install --binstubs --no-cache
rm -rf node_modules

if [ "$ISDEV" == "true" ]; then
   composer install --optimize-autoloader --no-interaction --no-scripts || (echo >&2 "Composer Install Dev Failed" && exit 1)
else
   composer install --optimize-autoloader --no-interaction --no-dev --no-scripts || (echo >&2 "Composer Install Prod Failed" && exit 1)
fi

if [ "$ISDEV" == "true" ]; then
   yarn install --dev
   yarn run encore dev
else
   yarn install
   yarn run encore production
fi

if [ "$ISDEV" == "true" ]; then
	php bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction
else
   php bin/console --env="$ENVIRONMENT" assetic:dump --no-interaction --no-debug
fi

chmod -R 777 var/cache
chmod -R 777 var/logs
chmod -R 777 temp
chmod -R 777 src/
