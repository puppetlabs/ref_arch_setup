# Running RAS in Docker
This experimental update allows running RAS in a Docker container. 
It uses docker-compose to set up an acceptance testing environment with 'controller' and 'master' containers.

## Dockerfile
The current configuration uses a Dockerfile with multi-stage builds:

* FROM ruby:alpine as base
* FROM base as sshd
* FROM base as build
* FROM base as prod

There are also stages for the docker acceptance tests:
* FROM prod as controller
* FROM sshd as master

## docker-compose.yml
The docker-compose.yml specifies a general 'ras' service as well as 'controller' and 'master' services for acceptance testing.

## .env
The .env file specifies default values for the parameters used in docker-compose.yml

## bin/docker
The scripts in bin/docker use the services specified in docker-compose.yml with the targets specified in the Dockerfile.

### attach
These scripts run and attach to the specified container, building the image if necessary.
* attach
* attach_build
* attach_master
* attach_controller

The `attach` script attaches to the specified target:
```
./bin/docker/attach prod
```

The other scripts attach to their respective default targets.

### build
Build the specified target using cached images or rebuild it from scratch
* build	
* rebuild
```
./bin/docker/rebuild prod
```

### ssh
* setup_ssh - Create the id_rsa, id_rsa.pub, and authorized_keys files (unless they already exist)
* ssh_entrypoint.sh - The entrypoint for the 'master' container in the acceptance test environment
	
### run
* ref_arch_setup - Run the 'ref_arch_setup' command in the ras container with the prod target
```
./bin/docker/ref_arch_setup install -h
```


## Acceptance test environment 

### Set up Docker on vmpooler
* To ensure a clean environment, run the rake task to provision a vmpooler controller and master with Docker installed on the controller:

```
ras.user:~/RubymineProjects/ref_arch_setup> be rake test:acceptance_setup_ras_docker_demo
```

* SSH to the vmpooler controller


### Set up the RAS puppercon environment
* Clone the repo with the puppercon branch and cd into ref_arch_setup:

```
[root@<vmpooler_controller> ~]# git clone -b puppercon --recurse-submodules https://github.com/puppetlabs/ref_arch_setup.git && cd ref_arch_setup
```

* Create ssh keys

The 'controller' and 'master' containers start with the ./fixtures/.ssh directory mounted. 
The setup_ssh script will create the id_rsa, id_rsa.pub, and authorized_keys files to allow ssh between the containers (unless they already exist).

```
[root@<vmpooler_controller> ref_arch_setup]# ./bin/docker/setup_ssh
```

### Test RAS
* Run the ref_arch_setup command in the ras container
```
[root@<vmpooler_controller> ref_arch_setup]# ./bin/docker/ref_arch_setup install -h
    Usage: ref_arch_setup install [options]

    Runs the install subcommands in the following order:
      generate-pe-conf (unless --pe-conf is provided)
      bootstrap
      pe-infra-agent-install (noop for "Standard" ref arch)
      configure
        ...
        
```

### Start the controller container
* Build and attach to the 'controller'
```
[root@<vmpooler_controller> ref_arch_setup]# ./bin/docker/attach_controller
```

* When the build completes you should have a bash prompt for the controller container
```
bash-4.4# bolt command run 'echo HELLO RAS!!!' --nodes=master --user=root --no-host-key-check
```

### Start the master container

* Launch a new terminal and SSH to the vmpooler controller

* Navigate to ref_arch_setup
```
[root@<vmpooler_controller> ~]# cd ref_arch_setup
```

* Build and attach to the 'master'
```
[root@<vmpooler_controller> ref_arch_setup]# ./bin/docker/attach_master
```

* When the build completes you should see sshd listening on port 22 on the master container
```
Server listening on 0.0.0.0 port 22.
Server listening on :: port 22.
```

### Back in the controller container

* Test bolt
```
bash-4.4# bolt command run 'echo HELLO RAS!!!' --nodes=master --user=root --no-host-key-check
```

* Run ref_arch_setup with the docker master
```
bash-4.4# ref_arch_setup install --pe-conf=pe.conf --pe-tarball=puppet-enterprise-2019.0-rc1-7-gd82666f-el-7-x86_64.tar --primary-master=master --user=root
```

### Teardown
* Exit the controller container
```
bash-4.4# exit
```

* Stop the 'master' container
```
[root@<vmpooler_controller> ref_arch_setup]# docker stop master
```

## Using the vmpooler master
The 'acceptance_setup_ras_docker_demo' rake task sets up ssh keys for the vmpooler controller and master.
The 'bin/docker/ref_arch_setup' script starts the container with ~/.ssh mounted, so bolt should work via ssh.

* Test ref_arch_setup using the fake tarball
```
[root@<vmpooler_controller> ref_arch_setup]# ./bin/docker/ref_arch_setup install --pe-conf=pe.conf --pe-tarball=puppet-enterprise-2019.0-rc1-7-gd82666f-el-7-x86_64.tar --primary-master=<vmpooler_master> --user=root
```

* Run ref_arch_setup to install the latest version of PE
```
[root@<vmpooler_controller> ref_arch_setup]# ./bin/docker/ref_arch_setup install --pe-conf=pe.conf --pe-version=latest --primary-master=<vmpooler_master> --user=root
```
