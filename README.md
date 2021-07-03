# MLProject setup creation and project run automated with Ansible

## Pre-requisites

* Create a CSC virual machine via OpenStack web interface
    * instructions in  https://github.com/korolainenriikka/mlflow_test README: follow 'Initial setup instructions' 

On the control node:
* Install pip and python3-dev: `sudo apt update && sudo apt install -y python3-pip python3-dev`

* Install ansible: `sudo pip install ansible`

* Install OpenStack command line tools
    * `sudo pip install python-keystoneclient python-novaclient python-glanceclient python-neutronclient`
    * download OpenStack RC file from https://pouta.csc.fi/dashboard/project/api_access/ and transfer it to the control node (easiest way is just to copy-paste contents)
    * run `source <project-name>-openrc.sh` to add the env variables needed to use OpenStack CLI

* Configure ssh
    * to add a ssh keypair to control node: run  `nova keypair-add ansible-control-node > openstack-access-key`
    * protect private key file with `chmod 0600 openstack-access-key`
    * start ssh agent and add private key to the agent with `eval $(ssh-agent) && ssh-add openstack-access-key`

! adding env variables and starting ssh-agent has to be re-run every time a new control node terminal is launched.

## Run the project

* Clone this project on the control host

* Modify the `vars` file:
    * add your conrol node's floating IP address
    * select [virtual machine flavor](https://docs.csc.fi/cloud/pouta/vm-flavors-and-billing/#cpouta-flavors)
    * add the uri of the mlproject git repo you wish to run
    * add the image name specified in your project's MLProject file (under docker_env: image:)

The default values run [a simple mnist project](https://github.com/korolainenriikka/mlflow_test)

* Create a virtual machine with `ansible-playbook create_vm.yml`
   * The 'Create a virtual machine' task occasionally fails because of the virtual machine spawning taking more time than usually. If this happens, run the delete env yml and re-try.     

* Install requirements with `ansible-playbook setup_env.yml -i inventory.txt`

* Run the mnist project with `ansible-playbook run_mlproject.yml -i inventory.txt`. All logs made by mlflow are stored in a zip file to the home directory of the control host.

* Restore the run environment to a pre-run state with `ansible-playbook clear_env.yml -i inventory.txt` (run this between model experiments to avoid confusion and/or name collisions etc.)

* Destroy the virtual machine and its environment with `ansible-playbook delete_mlflow_env.yml` (the setup has to be re-launched entirely if you with to change your vm's flavor)

## Troubleshooting

* Error messagels Auth plugin requires parameters which were not given: auth_url --> you are missing the env variables, download and source the RC file (openstackrc file does not give any indication on if password was correct or not, so if rc was sourced, the password may have been mistyped)

* A password prompt for ssh key appears in the 'Gathering facts' task of setup_env --> launch ssh agent and add the key

## Next steps

* add remote tracking server for saving of identifiers, metrics and artifacts

* change clear_env to use state:absent instead of rm to avoid unnecessary fails

