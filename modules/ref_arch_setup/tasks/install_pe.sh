#!/usr/bin/env bash

# Install PE:
# First, copy the PE installer tarball and pe_conf file to the node
# Then, execute the task as per the following example:
# bolt task --modulepath modules run 'ref_arch_setup::install_pe pe_tarball_path=puppet-enterprise-2018.1.1-el-7-x86_64.tar.gz pe_conf_path=pe.conf' --nodes bdjshmr8bx75q2a.delivery.puppetlabs.net


execute_command() {
    cmd=$1
    echo "Executing: $cmd"
    eval $cmd
    cmd_exit_code=$?

    # if number of args is 1, check for exit code = 0, otherwise check for exit code = value of second arg
    if [ $# -eq 1 ]
    then
        expected_exit_code=0
    else
        expected_exit_code=$2
    fi
    if [ $cmd_exit_code -ne $expected_exit_code ]
    then
        echo "Command '$1' failed - expected_exit_code: $expected_exit_code, actual_exit_code: $cmd_exit_code"
        exit 1
    fi
}

#check that pe.conf is present
if [ ! -f $PT_pe_conf_path ]; then
  echo "ERROR: Specified pe.conf file not found: $PT_pe_conf_path"
  exit 1
fi

#check that pe tarball is present
if [ ! -f $PT_pe_tarball_path ]; then
  echo "ERROR: Specified pe tarball not found: $PT_pe_tarball_path"
  exit 1
fi

# Install tar using existing package manager if it is not already installed
if [ "" == "`which tar`" ]
then
    echo "Tar Not Found"
    if [ -n "`which apt-get`" ]
    then
        execute_command "apt-get -y install tar"
    elif [ -n "`which yum`" ]
    then
        execute_command "yum -y install tar"
    else
        echo "OS does not have apt-get or yum package manager"
        exit 1
    fi
fi

execute_command "tar -xvf $PT_pe_tarball_path"
# Using -* so we don't have to know the specific version, or parse it from the install path
execute_command "sh ./puppet-enterprise-*/puppet-enterprise-installer -c $PT_pe_conf_path"
# Must run puppet agent twice, see https://puppet.com/docs/pe/2017.3/installing/installing_pe.html#text-mode-installation-options-for-monolithic-installations
execute_command "puppet agent -t" 2
execute_command "puppet agent -t" 2
exit 0
