ARG BRANCH=${BRANCH:-ce}
ARG OPTIMIZER_ORTOOLS_VERSION=${OPTIMIZER_ORTOOLS_VERSION}
ARG REGISTRY=${REGISTRY:-registry.mapotempo.com/}
ARG VROOM_VERSION=${VROOM_VERSION}
ARG BUNDLE_WITHOUT="development test"

# Install Vroom
FROM vroomvrp/vroom-docker:${VROOM_VERSION:-v1.8.0} as vroom

# Rake
FROM ${REGISTRY}mapotempo-${BRANCH}/optimizer-ortools:${OPTIMIZER_ORTOOLS_VERSION:-v1.5.0}

ARG BUNDLE_WITHOUT

LABEL maintainer="Mapotempo <tech@mapotempo.com>"

RUN apt-get update > /dev/null
RUN libgeos=$(apt-cache search 'libgeos-' | grep -P 'libgeos-\d.*' | awk '{print $1}')
RUN apt-get install -y git libgeos-dev ${libgeos} libicu-dev nano > /dev/null
RUN gem install bundler --version 2.1.4

ENV HOME /root
ENV LANG C.UTF-8
ENV REDIS_HOST redis-cache

COPY --chown=app . /srv/app/
COPY --chown=app --from=vroom /usr/local/bin /srv/vroom/bin

USER app
WORKDIR /srv/app

# Install app
RUN bundle install --path vendor/bundle --full-index --without ${BUNDLE_WITHOUT} -j $(nproc)

USER root
# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default

# Enable app
ADD docker/env.d/* /etc/nginx/main.d/
ADD docker/snippets/* /etc/nginx/snippets/
ADD docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Cleanup Debian packages
RUN apt-get remove -y git build-essential && \
  apt-get autoremove -y && \
  apt-get clean && \
  bundle clean --force && \
  echo -n > /var/lib/apt/extended_states && \
  rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
