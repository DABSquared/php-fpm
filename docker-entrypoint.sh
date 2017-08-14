#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ];  then

    if [[ -z "$GIT_REPO" && -z "$GIT_SSH_KEY" ]]
    then
        echo "No GIT Repository defined, not pulling."
        rm -rf .php_setup
        /setup.sh
        if [ "$ISDEV" == "true" ]; then
            #Save off the db dir number.
            numdirs=$(ls -l "$DB_DIR" | grep -v ^d | wc -l | xargs)
            echo "Number of db directories is $numdirs"
            if  [ $numdirs -le 2 ]; then
                php -d newrelic.appname="$symfony_app_name" bin/console --env="$ENVIRONMENT" doctrine:fixtures:load --no-interaction --multiple-transactions || (echo >&2 "Doctrine Fixtures Failed" && exit 1)
            fi
        fi
        echo "1" > .php_setup
    else
        echo "Pulling GIT Repository to /var/www/symfony"
        mkdir -p ~/.ssh
        eval "$(ssh-agent)" && ssh-agent -s
        echo "$GIT_SSH_KEY" > ~/.ssh/id_rsa
        chmod -R 0600 ~/.ssh/id_rsa
        ssh-add ~/.ssh/id_rsa
        [[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
        cd /var/www
        git clone "$GIT_REPO" symfony
        /setup.sh
    fi

fi

exec "$@"
