FROM ruby:alpine

ENV BUILD_PACKAGES build-base

# Update and install all of the required packages.
# At the end, remove the apk cache
RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/*

# Create the ras dir (future workdir) and copy the pe.conf
RUN mkdir /ras
COPY fixtures/pe.conf /ras/pe.conf

# Create ref_arch_setup dir and set as the workdir for the build
RUN mkdir /ref_arch_setup
WORKDIR /ref_arch_setup

# Copy requirements to install
COPY Gemfile /ref_arch_setup
COPY Gemfile.lock /ref_arch_setup
COPY ref_arch_setup.gemspec /ref_arch_setup

COPY lib/ref_arch_setup/version.rb /ref_arch_setup/lib/ref_arch_setup/version.rb

ADD ./gem_of /ref_arch_setup/gem_of

RUN bundle install

# Copy ref_arch_setup
COPY . /ref_arch_setup

# Build and install the gem
RUN bundle exec rake gem:build
RUN cd pkg && gem install ref_arch_setup && cd ..

# Switch the workdir and remove ref_arch_setup
WORKDIR /ras
RUN rm -rf /ref_arch_setup

