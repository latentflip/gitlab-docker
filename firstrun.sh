#!/bin/bash

# Regenerate the SSH host key
/bin/rm /etc/ssh/ssh_host_*
dpkg-reconfigure openssh-server

password=$(cat /srv/gitlab/config/database.yml | grep -m 1 password | sed -e 's/  password: "//g' | sed -e 's/"//g')

# ==============================================

# === Delete this section if restoring data from previous build ===

rm -R /srv/gitlab/data/postgresql
mv /var/lib/postgresql-tmp /srv/gitlab/data/postgresql

# Start postgres
service postgresql start

# Initialize postgres user and db
echo CREATE USER git|sudo -u postgres psql -d template1
echo CREATE DATABASE gitlabhq_production OWNER git|sudo -u postgres psql -d template1

# Precompile assets
cd /home/git/gitlab
su git -c "bundle exec rake assets:precompile RAILS_ENV=production"

cd /home/git/gitlab
su git -c "bundle exec rake gitlab:setup force=yes RAILS_ENV=production"
sleep 5
su git -c "bundle exec rake db:seed_fu RAILS_ENV=production"

# ================================================================

# Delete firstrun script
rm /srv/gitlab/firstrun.sh
