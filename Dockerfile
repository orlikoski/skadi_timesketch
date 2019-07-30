# Use the official Docker Hub Ubuntu 16.04 base image
FROM ubuntu:18.04

# Setup install environment and Timesketch dependencies
RUN apt-get update && apt-get -y install apt-transport-https \
    curl \
    git \
    libffi-dev \
    lsb-release \
    python-dev \
    python-pip \
    python-psycopg2

RUN curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - && \
    VERSION=node_8.x && \
    DISTRO="$(lsb_release -s -c)" && \
    echo "deb https://deb.nodesource.com/$VERSION $DISTRO main" > /etc/apt/sources.list.d/nodesource.list && \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" > /etc/apt/sources.list.d/yarn.list

# Install Plaso
RUN apt-get -y install software-properties-common && \
    add-apt-repository ppa:gift/stable && \
    apt-get update && \
    apt-get -y install python-plaso plaso-tools nodejs yarn && \
    apt-get -y dist-upgrade

# Build and Install Timesketch from GitHub Master with Pip
RUN git clone https://github.com/google/timesketch.git /tmp/timesketch && \
    cd /tmp/timesketch && git checkout tags/20190207 && yarn install && yarn run build && \
    sed -i -e '/pyyaml/d' /tmp/timesketch/requirements.txt && \
    pip install /tmp/timesketch/

# Install uwsgi
RUN apt-get -y install uwsgi uwsgi-plugin-python3

# Cleanup apt cache
RUN apt-get -y autoremove --purge && \
    apt-get -y clean && \
    apt-get -y autoclean && \
# Copy the Timesketch configuration file into /etc
    cp /usr/local/share/timesketch/timesketch.conf /etc
# Copy the TimeSketch uWSGI configuration file into the container
COPY uwsgi_config.ini /

# Copy the entrypoint script into the container
COPY docker-entrypoint.sh /
RUN chmod a+x /docker-entrypoint.sh

# Expose the port used by Timesketch
EXPOSE 5000

# Load the entrypoint script to be run later
ENTRYPOINT ["/docker-entrypoint.sh"]

# Invoke the entrypoint script
CMD ["timesketch"]
