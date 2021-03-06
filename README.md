# MLProject setup creation and project run automated with Ansible

This setup can be used to
* run MLflow projects that use a Docker environment
* view the runs in the UI using a remote tracking server

Bugs remaining in this setup
* expect module in tracking server initializations' volume preparation does not work correctly. You need to ssh to the environment, run `./volumesetup.sh` and answer to the prompts (agree/yes/etc. if the volume is empty. If not, do not use the tracking server init playbook)
* wait commands should be added to resize play for it to work every time.

## Pre-requisites

* Create a virtual machine via OpenStack web interface
    * instructions in  https://github.com/korolainenriikka/mlflow_test README: follow instructions under 'Create and run a virtual machine instance & connect remotely' 

On the control node (the one just created):
* Install pip and python3-dev: `sudo apt update && sudo apt install -y python3-pip python3-dev`

* Install ansible: `sudo pip install ansible`

* Install OpenStack command line tools
    * `sudo pip install python-openstackclient python-keystoneclient python-novaclient python-glanceclient python-neutronclient`
    * download OpenStack RC file from the openstack web interface (CSC: https://pouta.csc.fi/dashboard/project/api_access/) and transfer it to the control node (easiest way is just to copy-paste contents)
    * run `source [openrc_filename]` to add the env variables needed to use OpenStack CLI (the script will give no indication on if the password was correct, try re-sourcing this if you get an authentication error)

* Configure ssh
    * to add a ssh keypair to control node: run  `nova keypair-add ansible-control-node > openstack-access-key`
    * protect private key file with `chmod 0600 openstack-access-key`
    * start ssh agent and add private key to the agent with `eval $(ssh-agent) && ssh-add openstack-access-key`

! sourcing the RC file and starting ssh-agent has to be re-run every time a new control node terminal is launched.

## Run a project

* Clone this project on the control host

* Modify the `vars.txt` file:
    * add your conrol nodes' floating IP address
    * give a size of the volume created for storing tracking information (only used if tracking volume does not exist already)
    * select [virtual machine flavor](https://docs.csc.fi/cloud/pouta/vm-flavors-and-billing/#cpouta-flavors) (if you change this param later you need to run resize before the change takes place, see below)
    * add the uri of the mlproject git repository you wish to run
    * add the image name specified in your project's MLProject file (under docker_env: image:)
    * give the mlprojects' entrypoint, i.e. the path to MLProject and Dockerfile in your repository

The default values run [a simple mnist project](https://github.com/korolainenriikka/mlflow_test). On how to make your own model a MLflow project, see instructions in [MLflow documentation](https://mlflow.org/docs/latest/projects.html#specifying-projects) (use a Docker environment) and [the mlflow docker exaple project](https://github.com/mlflow/mlflow/tree/master/examples/docker). If you want your project to log the `vars.txt` contents to tracking (mainly to save information on the vm size used), add the line `mlflow.log_artifact('vars.txt')` to your projects' code inside the ` with mlflow.start_run():` block.

* Create virtual machine with `ansible-playbook create_vm.yml`, complete installations with `ansible-playbook setup_env.yml -i inv.txt`, and initialize the remote tracking server with `ansible-playbook tracking_server_init.yml -i inv.txt`
   * If volume setup script gets stuck (todo: fix extect command & remove ignore_errors): run `ssh ubuntu@[mlflow_env_ip]` and `./volumesetup.sh`. Answer yes to any prompts appearing (only on a blank volume!)
      * You see the environments' IP in the ansible terminal output  

* Run your project with `ansible-playbook run_mlproject.yml -i inv.txt [-e hparams='param1=value1 param2=value2]`
    * Use the optional hparams option to specify model hyperparameters (these should be listed in your MLProject file: [example](https://github.com/mlflow/mlflow/blob/master/examples/docker/MLproject))
    * If you want to run the same model with a commit version that has an updated Dockerfile, you need to clear the environment with `ansible-playbook clear-env.yml -i inv.txt` to use the new environment.

## Other commands

### Cleanup

* Shut the environment down and detach the volume with `ansible-playbook clear_env.yml -i inv.txt`     

* Destroy the virtual machine and its environment with `ansible-playbook delete_mlflow_env.yml`

### Re-launch mlflow tracking with existing run metrics & artifacts data on volume

* If you have previously run the cleanup, restart machine by running `openstack server unshelve mlflow_env`. Alternatively run the commands `ansible-playbook create_vm.yml` and `ansible-playbook setup_env.yml -i inv.txt` to create an environment. Then run `ansible-playbook relaunch-tracking.yml -i inv.txt`.
   * The relaunch will fail with the message "Cannot 'attach_volume' instance ... while it is in vm_state shelved_offloaded" if the unshelve operation is not finished.

### Resize the virtual environment

* Change the virtual machine flavor in `vars.txt`. Then run `ansible-playbook resize_environment.yml -i inv.txt`

### Export tracking data from the volume

On the control node run  `scp -i [path_to_private_key] -r ubuntu@[mlflow_env_ip]:/media/volume/* ~/export`. Then log out from the control node and run `scp -i [path_to_private_key] ubuntu@[control_node_ip]:~/export/* ~` to copy the tracking data to your local machine. 

## Troubleshooting

* 'skipping: no hosts matched' in any play --> the hosts information is missing, -i inv.txt option is missing

* Error message Auth plugin requires parameters which were not given: auth_url --> you are missing the env variables, download and source the RC file (openstackrc file does not give any indication on if password was correct or not, so if rc was sourced, the password may have been mistyped)

* A password prompt for ssh key appears in the 'Gathering facts' task of setup_env --> launch ssh agent and add the key

* Creating virtual machine fails without no apparent reason --> virtual machine spawning sometimes takes longer than ansible waits for task completion. Run `ansible-playbook delete_mlflow_env.yml` and then re-try creating the environment.
