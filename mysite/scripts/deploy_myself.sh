#!/bin/bash

### Exit on failure
set -e

### Define worker functions
function check_for_changed_files() {
    ### Check if there are any untracked changes to versioned files.
    ### If so, abort.
    if git ls-files -m | grep -q . ; then
        echo "Untracked changes exist; bailing out."
        exit 1
    fi
}

function update_to_latest() {
    ### Do a git fetch to get the latest code from "origin"
    git fetch origin

    ### Pull the latest code from origin/master into the current repo
    git merge origin/master --ff-only
}

function regenerate_static_files() {
    ### Use the Django staticfiles machinery to generate the
    ### /statik/ URL. This is a pretty hilarious URL. It's because
    ### we have have "static files" that we didn't make part of an
    ### "app" occuping /static/. So to support the Django staticfiles
    ### machinery, we map that to /statik/.
    mkdir -p mysite/statik
    python manage.py collectstatic --noinput
}

function update_database() {
    ### Initialize new databases, if necessary
    python manage.py syncdb

    ### Migrate databases, if necessary
    python manage.py migrate --merge
}

function notify_web_server() {
    ### Update the WSGI file so that Apache reloads the app.
    touch mysite/scripts/app.wsgi
}

function notify_github() {
    ### Update deploy_$(hostname) branch on github.com so that
    ### it is very clear which commits are deployed where.
    git push origin HEAD:deployed_$(hostname -f)
}

### Update the bug import code
cd ~/oh-bugimporters
check_for_changed_files
update_to_latest

### Update the main app
cd ~/milestone-a

check_for_changed_files
update_to_latest
regenerate_static_files
notify_github
update_database
notify_web_server
