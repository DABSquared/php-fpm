#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ] || [ "$1" = 'alternative.sh' ] ;  then
   
	if [ "$ISDEV" == "true" ]; then
		rm -rf .php_setup
		cp /setup.sh ./setup.sh
		chmod a+x ./setup.sh
		./setup.sh
	else
      	  	echo -e "\nopcache.validate_timestamps=0" >> /usr/local/etc/php/php.ini
	fi
	
	php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" doctrine:migrations:migrate --no-interaction || (echo >&2 "Doctrine Migrations Failed" && exit 1)
    if [ "$ISDEV" == "true" ]; then
		#Save off the db dir number.
		numdirs=$(ls -l "$DB_DIR" | grep -v ^d | wc -l | xargs)
		echo "Number of db directories is $numdirs"
		if  [ $numdirs -le 2 ]; then
			php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" doctrine:fixtures:load --no-interaction --multiple-transactions || (echo >&2 "Doctrine Fixtures Failed" && exit 1)
		fi
    fi
   

	if [ "$ISDEV" == "true" ]; then
		php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" cache:warmup || (echo >&2 "Cache Warmup Dev Failed" && exit 1)
	else
		php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" cache:warmup --no-debug || (echo >&2 "Cache Warmup Prod Failed" && exit 1)
	fi

    if [ "$ISDEV" == "true" ]; then
        echo "1" > .php_setup
    fi

fi

exec "$@"
