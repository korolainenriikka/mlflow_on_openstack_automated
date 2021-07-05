#!/bin/bash

#ansible-playbook create_vm.yml &&
#ansible-playbook setup_env.yml -i inventory.txt &&
ansible-playbook tracking_server_init.yml -i inventory.txt &&
ansible-playbook run_mlproject.yml -i inventory.txt

