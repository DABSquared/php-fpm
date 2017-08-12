#!/bin/bash
set -eo pipefail
shopt -s nullglob

if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ];  then

    if [[ -z "$GIT_REPO" && -z "$GIT_SSH_KEY" ]]
    then
        echo "No GIT Repository defined, not pulling."
        rm -rf .php_setup
        /setup.sh
        echo "1" > .php_setup
    else
        echo "Pulling GIT Repository to /var/www/symfony"
        eval $(ssh-agent -s)
        echo "$GIT_SSH_KEY" > test.key
        chmod -R 600 test.key
        ssh-add test.key
        mkdir -p ~/.ssh
        [[ -f /.dockerenv ]] && echo -e "Host *\n\tStrictHostKeyChecking no\n\n" > ~/.ssh/config
        cd /var/www
        git clone "$GIT_REPO" symfony
        /setup.sh
    fi

fi

exec "$@"
