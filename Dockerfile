FROM ubuntu:14.04

# Run upgrades and dependencies
RUN echo deb http://us.archive.ubuntu.com/ubuntu/ precise universe multiverse >> /etc/apt/sources.list;\
  echo deb http://us.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe >> /etc/apt/sources.list;\
  echo deb http://security.ubuntu.com/ubuntu precise-security main restricted universe >> /etc/apt/sources.list;\
  echo udev hold | dpkg --set-selections;\
  echo initscripts hold | dpkg --set-selections;\
  echo upstart hold | dpkg --set-selections;\
  apt-get update;\
  apt-get -y upgrade;\
  apt-get install -y build-essential zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libncurses5-dev libffi-dev curl openssh-server redis-server checkinstall libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev sudo python-docutils nginx logrotate vim postfix git-core postgresql-9.3 postgresql-client libpq-dev

# Install Ruby
# For info on that patch to readline see this super cool issue https://github.com/sstephenson/ruby-build/issues/526
RUN mkdir /tmp/ruby;\
  cd /tmp/ruby;\
  curl ftp://ftp.ruby-lang.org/pub/ruby/2.0/ruby-2.0.0-p451.tar.gz | tar xz;\
  cd ruby-2.0.0-p451;\
  chmod +x configure;\
  curl https://gist.githubusercontent.com/riocampos/b2669b26016207224f06/raw/0d3c9229eb1083ae08080b21bdf0a7ebaeda5113/readline.patch|patch -p0;\
  ./configure --disable-install-rdoc;\
  make;\
  make install;\
  gem install bundler --no-ri --no-rdoc

# Create Git user
RUN adduser --disabled-login --gecos 'GitLab' git

# Install GitLab Shell
RUN cd /home/git;\
  su git -c "git clone https://gitlab.com/gitlab-org/gitlab-shell.git -b v1.9.3";\
  cd gitlab-shell;\
  su git -c "mv config.yml.example config.yml";\
  sed -i -e 's/localhost/127.0.0.1/g' config.yml;\
  su git -c "./bin/install"

# Install GitLab
RUN cd /home/git;\
  su git -c "git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b 6-8-stable gitlab"

# Misc configuration stuff
RUN cd /home/git/gitlab;\
  chown -R git tmp/;\
  chown -R git log/;\
  chmod -R u+rwX log/;\
  chmod -R u+rwX tmp/;\
  chmod -R u+rwX public/uploads;\
  su git -c "cp config/unicorn.rb.example config/unicorn.rb";\
  su git -c "cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb";\
  su git -c "git config --global user.name 'GitLab'";\
  su git -c "git config --global user.email 'gitlab@localhost'";\
  su git -c "git config --global core.autocrlf input"

RUN cd /home/git/gitlab;\
  su git -c "bundle install --deployment --without development test mysql aws"

# Install init scripts
RUN cd /home/git/gitlab;\
  cp lib/support/init.d/gitlab /etc/init.d/gitlab;\
  update-rc.d gitlab defaults 21;\
  cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab

EXPOSE 80
EXPOSE 22

ADD . /srv/gitlab

RUN chmod +x /srv/gitlab/start.sh;\
  chmod +x /srv/gitlab/firstrun.sh

CMD ["/srv/gitlab/start.sh"]
