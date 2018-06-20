#!/usr/bin/env bash

# Install PE:
# Because puppet is not installed, this needs to be executed as a command, not a task
# It also cannot be a script because it requires options with arguments for the script
# First, copy the install_pe.sh script, the PE installer tarball and pe_conf file to the node
# Then, execute the command as per the following example:
# bolt command run './install_pe.sh -i puppet-enterprise-2018.1.1-el-7-x86_64.tar.gz -p pe.conf' --nodes bdjshmr8bx75q2a.delivery.puppetlabs.net

usage() {
    echo "        -i The path to the PE installer"
    echo "        -p The path to the pe.conf file"
    exit 1;
}

while getopts ":i:p:" opt; do
    case $opt in
        i)
            INSTALLER_PATH=$OPTARG
            ;;
        p)
            PE_CONF_PATH=$OPTARG
            ;;
        \?)
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit 1
            ;;
    esac
done

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
        echo "Command '$1' failed - expected_exit_code: $expected_exit_code, actual_exit_code: cmd_exit_code"
        exit 1
    fi
}

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

execute_command "tar -xvf $INSTALLER_PATH"
# Using -* so we don't have to know the specific version, or parse it from the install path
# TODO: this could break if customer renames the downloaded tarball
execute_command "sh ./puppet-enterprise-*/puppet-enterprise-installer -c $PE_CONF_PATH"
execute_command "puppet agent -t" 2
execute_command "puppet agent -t" 2
exit 0
