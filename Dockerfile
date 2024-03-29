# redmine_git_hosting is not working with Debian Bookworm at the moment (20.09.2023)
# before update:
# > test Redmine Administration -> Redmine Git Hosting -> Rescue -> Flush Git Cache?
# > in docker container /usr/src/redmine/log/git_hosting.log should not report any errors during gitolite-admin repo cloning
FROM redmine:5.0.4

# install dependencies
RUN apt-get update && apt-get install -y \
	build-essential \
	cmake \
	debconf-utils \
	pkg-config \
	imagemagick \
	libmagickwand-dev \
	libssh2-1 \
	libssh2-1-dev \
	libssl-dev \
	libgpg-error-dev \
	curl \
	sudo

# prevent permission error when running bundle install
RUN chown -R redmine:redmine /usr/local/bundle

# prepare redmine user for gitolite
RUN mkdir -p /home/redmine/.ssh && \
    usermod --shell /bin/bash redmine && \
    ssh-keygen -m PEM -N '' -f /home/redmine/.ssh/id_rsa && \
    chown -R redmine:redmine /home/redmine

# install gitolite as apt-package
RUN adduser --gecos "" --disabled-password  --shell /bin/bash --home /home/git git

RUN echo "gitolite3 gitolite3/gitdir string /home/git" | debconf-set-selections && \
    echo "gitolite3 gitolite3/gituser string git" | debconf-set-selections && \
    echo "gitolite3 gitolite3/adminkey string /home/redmine/.ssh/id_rsa.pub" | debconf-set-selections

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y gitolite3 && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i -e "s/GIT_CONFIG_KEYS.*/GIT_CONFIG_KEYS  =>  '.*',/g" /etc/gitolite3/gitolite.rc && \
    sed -i -e "s/# LOCAL_CODE.*=>.*\"\$ENV{HOME}\/local\"/LOCAL_CODE => \"\$ENV{HOME}\/local\"/" /etc/gitolite3/gitolite.rc

RUN sed -i -e "s/#Port 22/Port 2222/g" /etc/ssh/sshd_config && \
    sed -i -e "s/AcceptEnv LANG .*/#AcceptEnv LANG LC_\*/g" /etc/ssh/sshd_config && \
    # redmine_git_hosting seem to except only RSA host keys, so force the daemon \
    # to only use rsa host keys. maybe this could removed, when updating to debian bookworm (see FROM)
    echo "HostKeyAlgorithms ssh-rsa" >> /etc/ssh/sshd_config

# clone redmine git hosting repository & fix dependency problem
RUN cd /usr/src/redmine/plugins && \
    git clone https://github.com/AlphaNodes/additionals.git -b 3.0.6 && \
    git clone https://github.com/jbox-web/redmine_git_hosting.git -b 6.0.0

COPY ./sudoers.d/redmine /etc/sudoers.d/redmine
COPY ./plugins /usr/src/redmine/plugins
COPY ./gitolite-entrypoint.sh /gitolite-entrypoint.sh

RUN chmod 440 /etc/sudoers.d/redmine

RUN gosu redmine sh -c "bundle config set --local without 'development:test'" && \
    gosu redmine sh -c "bundle config set --local build.rugged --with-ssh" && \
    gosu redmine sh -c "bundle install"

# clone themes
RUN cd /usr/src/redmine/public/themes && \
    git clone https://github.com/makotokw/redmine-theme-gitmike.git redmine-theme-gitmike && \
    git clone https://github.com/mrliptontea/PurpleMine2.git redmine-theme-purplemine2 && \
    git clone https://github.com/akabekobeko/redmine-theme-minimalflat2.git redmine-theme-minimalflat2 && \
    git clone -b redmine4.2  https://github.com/farend/redmine_theme_farend_bleuclair.git redmine-theme-bleuclair

ENTRYPOINT ["/gitolite-entrypoint.sh"]
CMD ["rails", "server", "-b", "0.0.0.0"]
