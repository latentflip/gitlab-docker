#!/bin/bash

# Regenerate the SSH host key
/bin/rm /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

# Persiste postgres onto host
rm -R /srv/gitlab/data/postgresql
mv /var/lib/postgresql-tmp /srv/gitlab/data/postgresql

# Persist gitlab/public onto host (for nginx to serve)
rm -R /srv/gitlab/data/gitlab-public
mv /home/git/gitlab/public-tmp /srv/gitlab/data/gitlab-public

# Start postgres
service postgresql start

# Initialize postgres user and db
echo CREATE USER git|sudo -u postgres psql -d template1
echo CREATE DATABASE gitlabhq_production OWNER git|sudo -u postgres psql -d template1

# Precompile assets
cd /home/git/gitlab
su git -c "bundle exec rake assets:precompile RAILS_ENV=production"
su git -c "bundle exec rake gitlab:setup force=yes RAILS_ENV=production"

# ================================================================
