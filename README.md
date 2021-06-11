# Mnist MLProject run automated with Ansible

current: has working playbooks for VM creating & cleanup.

next steps:
1. parametrize IP addresses
2. make repo public
3. start working on mlflow env installations

## Pre-requisites

* Create a CSC virual machine via OpenStack web interface
    * instructions in  https://github.com/korolainenriikka/mlflow_test README: follow 'Initial setup instructions' 

On the control node:
* Install pip and python3-dev: `sudo apt update && sudo apt install -y python3-pip python3-dev`

* Install ansible: `sudo pip install ansible`

* Install OpenStack command line tools
    * `sudo pip install python-keystoneclient python-novaclient python-glanceclient python-neutronclient`
    * download OpenStack RC file from https://pouta.csc.fi/dashboard/project/api_access/
    * run `source <project-name>-openrc.sh` to add the env variables needed to use OpenStack CLI

* Add a ssh keypair to control node
    * run  `nova keypair-add ansible-control-node > openstack-access-key`


# Troubleshooting

* Auth plugin requires parameters which were not given: auth_url --> you are missing the env variables, download and source the RC file
