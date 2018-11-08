### Environment ###
FROM ruby:alpine as base

ENV BUILD_PACKAGES build-base bash

# Update, install required packages, remove apk cache
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/*

# Create ref_arch_setup dir and set as the workdir
RUN mkdir /ref_arch_setup
WORKDIR /ref_arch_setup

### Build ###
FROM base as build

# Copy requirements for install
COPY Gemfile /ref_arch_setup
COPY ref_arch_setup.gemspec /ref_arch_setup
COPY lib/ref_arch_setup/version.rb /ref_arch_setup/lib/ref_arch_setup/version.rb
ADD ./gem_of /ref_arch_setup/gem_of

# Install the dependencies
RUN bundle install

# Copy ref_arch_setup
COPY . /ref_arch_setup

# Build and install the gem
RUN bundle exec rake gem:build
RUN cd pkg && gem install ref_arch_setup && cd ..

### Production ###
FROM base as prod

COPY fixtures/pe.conf /ref_arch_setup/pe.conf
COPY --from=build /ref_arch_setup/pkg /ref_arch_setup/pkg

RUN cd pkg && gem install ref_arch_setup --no-rdoc --no-ri && cd ..
RUN rm -rf /ref_arch_setup/pkg

### Acceptance ###
FROM prod as acceptance
COPY fixtures/*.tar /ref_arch_setup
