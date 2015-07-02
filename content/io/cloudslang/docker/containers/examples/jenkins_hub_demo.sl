#   (c) Copyright 2014 Hewlett-Packard Development Company, L.P.
#   All rights reserved. This program and the accompanying materials
#   are made available under the terms of the Apache License v2.0 which accompany this distribution.
#
#   The Apache License is available at
#   http://www.apache.org/licenses/LICENSE-2.0
#
####################################################
# Do some docker stuff
#
# Inputs:
#   - nodes_list - list of the nodes
# Outputs:
#   - error_message - error message
# Results:
#   - SUCCESS
#   - FAILURE
####################################################

namespace: io.cloudslang.docker.containers.examples

imports:
  containers: io.cloudslang.docker.containers

flow:
  name: jenkins_hub_demo
  inputs:
#    required
    - nodes_list
    - hub
    - remote: "'true'"
    - hub_container_name: "'selenium-hub'"
    - hub_host: hub.get('host')
    - hub_username: hub.get('username')

#    optional
    - hub_port:
        required: false
        default: hub.get('port')
    - hub_grid_port:
        required: false
        default: hub.get('grid_port', '4444')
    - hub_image_name:
        required: false
        default: hub.get('image_name')
    - hub_password:
        required: false
        default: hub.get('password')
    - hub_private_key_file:
        required: false
        default: hub.get('private_key_file')

  workflow:
    - run_hub_container:
        do:
          containers.run_container:
            - container_name: hub_container_name
            - container_params: >
                '-p ' + hub_grid_port + ':4444'
            - image_name: hub_image_name
            - host: hub_host
            - port:
                required: false
                default: hub_port
            - username: hub_username
            - password:
                required: false
                default: hub_password
            - private_key_file:
                required: false
                default: hub_private_key_file

    - get_ip:
        do:
          containers.get_container_ip:
            - container_name: hub_container_name
            - host: hub_host
            - port:
                required: false
                default: hub_port
            - username: hub_username
            - password:
                required: false
                default: hub_password
            - private_key_file:
                required: false
                default: hub_private_key_file
        publish:
          - container_ip: returnResult
          - error_message

    - run_nodes_containers:
        loop:
          for: node in nodes_list
          do:
            containers.run_container:
              - container_name: node.get('container_name')
              - hub_ip: hub_host if remote == 'true' else container_ip
              - container_params: >
                  "-p :5555
                  -e HUB_PORT_4444_TCP_ADDR=" + hub_ip +
                  " -e HUB_PORT_4444_TCP_PORT=" + hub_grid_port +
                  " -e REMOTE_HOST_PARAM=" + remote
              - image_name: node.get('image_name')
              - host: node.get('host')
              - port:
                  required: false
                  default: node.get('port')
              - username: node.get('username')
              - password:
                  required: false
                  default: node.get('password')
              - private_key_file:
                  required: false
                  default: node.get('private_key_file')

  outputs:
    - error_message

  results:
    - SUCCESS
    - FAILURE