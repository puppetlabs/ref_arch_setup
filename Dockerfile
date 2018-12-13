FROM ruby:alpine as alpine

ENV PACKAGES build-base bash openssh openrc

# Update, install required packages, remove apk cache
RUN apk update && \
    apk upgrade && \
    apk add $PACKAGES && \
    rm -rf /var/cache/apk/*

##################################################################

FROM alpine as build

RUN mkdir /ref_arch_setup
WORKDIR /ref_arch_setup

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

##################################################################

FROM centos:centos7 as centos

ENV PACKAGES tar which openssh-server passwd

RUN yum -y update; yum clean all
RUN yum -y install $PACKAGES

RUN mkdir /ref_arch_setup
WORKDIR /ref_arch_setup

##################################################################

FROM centos as bolt

RUN rpm -Uvh https://yum.puppet.com/puppet6/puppet6-release-el-7.noarch.rpm
RUN yum install -y puppet-bolt-1.5.0

##################################################################

FROM bolt as prod

COPY fixtures/pe.conf /ref_arch_setup/pe.conf
COPY --from=build /ref_arch_setup/pkg /ref_arch_setup/pkg

RUN cd pkg && /opt/puppetlabs/bolt/bin/gem install ref_arch_setup --no-rdoc --no-ri && cd ..
RUN rm -rf /ref_arch_setup/pkg

RUN ln -s /opt/puppetlabs/bolt/bin/ref_arch_setup /usr/local/bin/ref_arch_setup

##################################################################

FROM prod as controller
COPY fixtures/tarball/*.tar /ref_arch_setup

##################################################################

FROM alpine as alpine-ssh

# Update sshd config
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN mkdir -p /var/run/sshd

COPY bin/docker/ssh_entrypoint.sh /usr/local/bin/

EXPOSE 22
ENTRYPOINT ["ssh_entrypoint.sh"]

##################################################################

FROM alpine-ssh as master
