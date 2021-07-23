# MLProject setup creation and project run automated with Ansible

## Pre-requisites

* Create a CSC virual machine via OpenStack web interface
    * instructions in  https://github.com/korolainenriikka/mlflow_test README: follow 'Initial setup instructions' 

On the control node:
* Install pip and python3-dev: `sudo apt update && sudo apt install -y python3-pip python3-dev`

* Install ansible: `sudo pip install ansible`

* Install OpenStack command line tools
    * `sudo pip install python-openstackclient python-keystoneclient python-novaclient python-glanceclient python-neutronclient`
    * download OpenStack RC file from https://pouta.csc.fi/dashboard/project/api_access/ and transfer it to the control node (easiest way is just to copy-paste contents)
    * run `source <project-name>-openrc.sh` to add the env variables needed to use OpenStack CLI

* Configure ssh
    * to add a ssh keypair to control node: run  `nova keypair-add ansible-control-node > openstack-access-key`
    * protect private key file with `chmod 0600 openstack-access-key`
    * start ssh agent and add private key to the agent with `eval $(ssh-agent) && ssh-add openstack-access-key`

! adding env variables and starting ssh-agent has to be re-run every time a new control node terminal is launched.

## Run a project

* Clone this project on the control host

* Modify the `vars.txt` file:
    * add your conrol nodes' floating IP address
    * give a size of the volume created for storing tracking information (only used if tracking volume does not exist already)
    * select [virtual machine flavor](https://docs.csc.fi/cloud/pouta/vm-flavors-and-billing/#cpouta-flavors)
    * add the uri of the mlproject git repo you wish to run
    * add the image name specified in your project's MLProject file (under docker_env: image:)
    * give the mlprojects' entrypoint, ie the path to MLProject and Dockerfile in your repository

The default values run [a simple mnist project](https://github.com/korolainenriikka/mlflow_test)

* Create virtual machine with `ansible-playbook create_vm.yml`, complete installations with `ansible-playbook setup_env.yml -i inv.txt`, and initialize the remote tracking server with `ansible-playbook tracking_server_init.yml -i inv.txt`

* Run your project with `ansible-playbook run_mlproject.yml -i inv.txt [-e hparams='param1=value1 param2=value2]`
    * Use the optional hparams option to specify model hyperparameters (these should be listed in your MLProject file: [example](https://github.com/mlflow/mlflow/blob/master/examples/docker/MLproject))
    * If you want to run the same model with a commit version that has an updated Dockerfile, you need to clear the environment with `ansible-playbook clear-env.yml -i inv.txt` to use the new environment.

* Resize the environment you use for training by changing the vm_flavor parameter in `vars.txt` and running `ansible-playbook scale-environment.yml -i inv.txt`

* Destroy the virtual machine and its environment with `ansible-playbook delete_mlflow_env.yml`

## Troubleshooting

* 'skipping: no hosts matched' in any play --> the hosts information is missing, -i inv.txt option is missing

* Error message Auth plugin requires parameters which were not given: auth_url --> you are missing the env variables, download and source the RC file (openstackrc file does not give any indication on if password was correct or not, so if rc was sourced, the password may have been mistyped)

* A password prompt for ssh key appears in the 'Gathering facts' task of setup_env --> launch ssh agent and add the key

* Creating virtual machine fails without no apparent reason --> virtual machine spawning sometimes takes longer than ansible waits for task completion. Run `ansible-playbook delete_mlflow_env.yml` and then re-try creating the environment.
