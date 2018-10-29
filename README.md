# RefArchSetup

## Overview
RefArchSetup is a Ruby gem designed to help install the various Puppet Reference Architectures. 
It currently supports the Standard Reference Architecture.

# Prerequisites
## Ruby
RefArchSetup uses [Puppet Bolt](https://puppet.com/products/puppet-bolt) as a gem which requires a minimum Ruby version of 2.3.

## Root Access
RefArchSetup executes Bolt commands as the root user using the `--run-as root` option to ensure a successful PE installation. 
See the [Bolt Options](#bolt-options) section for more information.

## Supported Platforms
RefArchSetup supports the following platforms:

| OS                                                  | Arch   |
|:----                                                |:----   |
| EL (RHEL, CentOS, Scientific Linux, Oracle Linux) 6 | x86_64 |
| EL (RHEL, CentOS, Scientific Linux, Oracle Linux) 7 | x86_64 |
| SLES 12                                             | x86_64 |
| Ubuntu 16.04                                        | amd64  |
| Ubuntu 18.04                                        | amd64  |

## Supported PE Versions
RefArchSetup supports PE versions greater than 2018.1.0.

## Supported Reference Architectures
RefArchSetup currently supports the Standard Architecture.

# Installation
RefArchSetup can be installed via [RubyGems](https://rubygems.org/gems/ref_arch_setup) or by building the gem locally. 

## Install via RubyGems
The easiest way to install RefArchSetup is via [RubyGems](https://rubygems.org/gems/ref_arch_setup):
```
    $ gem install ref_arch_setup
```

## Build the gem locally
To build the gem locally:
* Clone the RefArchSetup and install the dependencies by following the steps in the [Getting Started](CONTRIBUTING.md) section in [CONTRIBUTING.md](CONTRIBUTING.md)
* From your local copy of the repo, build the gem using the provided rake task:
```
    $ ~/ref_arch_setup> bundle exec rake gem:build
```
* The gem will be built to the pkg directory. Install the gem by either specifying the path to the RAS gem provided in the output from the previous step:
```
    $ ~/ref_arch_setup> gem install pkg/ref_arch_setup-0.0.x
```
or navigate to the pkg directory first, in which case specifying the version is not required:
```
    $ ~/ref_arch_setup> cd pkg && gem install ref_arch_setup
```

# Usage
## Help
RefArchSetup provides help on the command line. Run the `ref_arch_setup` command with the ` -h` option to display the available commands and options:
```
    $ ref_arch_setup -h
    Usage: ref_arch_setup <command> [subcommand] [options]
  
    Available Commands:
  
      install                         - Install a bootstrapped PE on target host
      install generate-pe-conf        - Generates a pe.conf for the install
      install bootstrap               - Installs a bare PE on the target host
      install pe-infra-agent-install  - Installs agents on all PE
                                        infrastructure nodes
      install configure               - Configures PE infrastructure nodes to
                                        reference architecture settings
  
    Available Options:
  
      -h, --help                       Prints this help
      -v, --version                    Show current version of ref_arch_setup
      
```

Run the `ref_arch_setup install` sub-command with the ` -h` option to display the available sub-commands and options:
```
    $ ref_arch_setup install -h
    Usage: ref_arch_setup install [options]

    Runs the install subcommands in the following order:
      generate-pe-conf (unless --pe-conf is provided)
      bootstrap
      pe-infra-agent-install (noop for "Standard" ref arch)
      configure

    Available Options:
      Either --console-password or --pe-conf required
        --user <username>               SSH username for bolt ssh to target host
        --password <password>           SSH password for bolt ssh to target host
        --private-key <path>            Path to SSH private key file for bolt
                                        ssh to target host
        --sudo-password <password>      Root user password for privilege escalation
        --console-password <password>   Password for the PE console
        --primary-master <hostname>     Hostname of primary master
        --pe-tarball <path|URL>         Path or URL to PE tarball
        --pe-version <version>          PE version to get tarball for
        --pe-conf <path>                Path to pe.conf file
```

## Install
Install PE on the desired primary master using the install command. For example:
```
    ref_arch_setup install --primary-master=localhost --pe-version=latest --pe-conf=/path/to/pe.conf
```

### --primary-master
RefArchSetup can perform the PE installation with a local or remote primary master.

#### Specifying a local primary master
To perform the PE installation on the same host where RefArchSetup is run, specify `--primary-master=localhost`

#### Specifying a remote primary master
To perform the PE installation on a remote host, specify `--primary-master=my.remote.master`
If a remote host is specified it must be accessible to Bolt; see the [Bolt Options](#bolt-options) section for more information.

### --pe-tarball
Specifying a PE tarball is optional, but if the option is specified it will override the `--pe-version` option.

#### Specifying a tarball URL
To install PE using a tarball URL, specify `--pe-tarball=https://my.host.tarball.tar.gz`

#### Specifying a tarball path
To install PE using a tarball on a local or remote filesystem, specify `--pe-tarball=/path/to/tarball.tar.gz`.

### --pe-version
RefArchSetup can install a specific version of PE or the latest version. 
See the [Puppet Enterprise Version History](https://puppet.com/misc/version-history) for a comprehensive list of PE versions.

#### Install a specific version
To install a specific version of PE, specify the version number: `--pe-version=2018.1.4`.

#### Install the latest version 
To install the latest version, specify `--pe-version=latest`.

### --pe-conf
PE installation requires a valid pe.conf file. At a minimum the "console_admin_password" option must be specified.
RefArchSetup provides a default [pe.conf](fixtures/pe.conf) file. Specify the path to the pe.conf file: `--pe-conf=/path/to/pe.conf`

## Bolt Options

### --sudo-password
RefArchSetup executes Bolt commands as the root user using the `--run-as` option. 
If RefArchSetup is run as a user other than root the sudo password must be specified: `--sudo-password=mysudopassword`

### --user
To execute Bolt commands via ssh with a user other than the user running RefArchSetup, specify `--user=my.ssh.user`. 
Bolt can authenticate using a password or a private key file.

### --password
To authenticate using a password, specify `--password=mypassword`.

### --private-key
To authenticate using a private key, specify `--private-key=/path/to/my_key.rsa`.

# License
See [LICENSE](LICENSE) file.

# Support & Issues
Please log tickets and issues in the 
[SLV project](https://tickets.puppetlabs.com/projects/SLV/).

For additional information on filing tickets, please check out our
[CONTRIBUTOR doc](CONTRIBUTING.md).

# Maintainers
For information on project maintainers, please check out our
[MAINTAINERS doc](MAINTAINERS.md).
