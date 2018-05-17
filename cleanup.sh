#!/bin/bash
cd kubernetes
ansible-playbook -i ansible/inventory/inventory ansible/playbooks/delete_cluster.yml
