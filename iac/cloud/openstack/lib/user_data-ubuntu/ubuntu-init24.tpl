#cloud-config
%{if ca_certificates != ""~}
ca_certs:
  trusted:
  - |
   ${indent(3, ca_certificates)}
%{endif~}


package_update: true
package_upgrade: true
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common
  - jq
%{if reboot == true~}
power_state:
  mode: reboot
%{endif~}

runcmd:
  - echo $( curl -s http://169.254.169.254/latest/meta-data/local-ipv4; echo "" ; curl -s http://169.254.169.254/latest/meta-data/hostname | cut -d '.' -f 1) >> /etc/hosts
  - modprobe br_netfilter
  - systemctl restart systemd-modules-load
  - systemctl restart systemd-timesyncd
  - sysctl -w net.bridge.bridge-nf-call-iptables=1
  - sysctl -w vm.overcommit_memory=1
  - sysctl -w kernel.panic=10
  - sysctl -w kernel.panic_on_oops=1
  - sysctl -w fs.inotify.max_user_watches=65536
%{if pf9_onboard == true~}
  - curl "${pf9ctl_setup_download_url}/pf9ctl_setup" -o /home/${ssh_user}/pf9ctl_setup
  - sudo chmod u+x /home/${ssh_user}/pf9ctl_setup
  - sudo bash "/home/${ssh_user}/pf9ctl_setup"
  - sudo pf9ctl config set --no-prompt --account-url ${pf9_account_url} --password '${pf9_password}' --username '${pf9_username}' --tenant ${pf9_tenant} --region ${pf9_region}
  - sudo pf9ctl prep-node --no-prompt --skip-checks
%{endif~}

users:
  - default
  - name: ${ssh_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
%{for key in ssh_authorized_keys~}
      - ${key}
%{endfor~}
write_files:
%{if pf9_onboard == true~}
  - content: |
      #!/bin/bash

      pf9_username='${pf9_username}'
      pf9_password='${pf9_password}'
      pf9_tenant='${pf9_tenant}'
      pf9_account_url='${pf9_account_url}'
      pf9_region='${pf9_region}'
      node_name=$(curl -s http://169.254.169.254/latest/meta-data/hostname | cut -d '.' -f 1)
      node_ip="$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)"

      QBERT_URL="$pf9_account_url/qbert/v4"
      RSMGR_URL="$pf9_account_url/resmgr/v1/hosts"

      if [ -f /etc/pf9/kubelet.env ]
      then
        export $(cat /etc/pf9/kubelet.env | xargs)
      elif [ -f /etc/pf9/kube.env ]
      then
        source /etc/pf9/kube.env
      fi


      function get_token() {
        BASE_URL="https://$pf9_account_url"
        AUTH_REQUEST_PAYLOAD="{
        \"auth\":{
          \"identity\":{
            \"methods\":[
              \"password\"
            ],
            \"password\":{
              \"user\":{
                \"name\":\"$pf9_username\",
                \"domain\":{
                  \"id\":\"default\"
                  },
                \"password\":\"$pf9_password\"
                }
              }
            },
          \"scope\":{
            \"project\":{
              \"name\":\"$pf9_tenant\",
              \"domain\":{
                \"id\":\"default\"
                }
              }
            }
          }
        }"
        # ===== KEYSTONE API CALLS ====== #
        KEYSTONE_URL="$pf9_account_url/keystone/v3"

        X_AUTH_TOKEN=$(curl -si \
          -H "Content-Type: application/json" \
          $KEYSTONE_URL/auth/tokens\?nocatalog \
          -d "$AUTH_REQUEST_PAYLOAD" | grep -i ^X-Subject-Token: | cut -f2 -d':' | tr -d '\r' | tr -d ' ')

        PROJECT_UUID=$(curl -s \
          -H "Content-Type: application/json" \
          -H "X-AUTH-TOKEN: $X_AUTH_TOKEN" \
          $KEYSTONE_URL/auth/projects | jq -r '.projects[] | select(.name == '\"$pf9_tenant\"') | .id')
      }

      function get_node_id(){

        #If we dont find the env variable find it from the API
        if [[ -z $HOSTID  ]]; then
          HOSTID=$(curl -s \
            -H "X-AUTH-TOKEN: $X_AUTH_TOKEN" \
            $QBERT_URL/$PROJECT_UUID/nodes | jq \
            --arg node_name_var $node_name --arg node_ip_var $node_ip '.[] | select(.name == $node_name_var) | select(.primaryIp == $node_ip_var)' | jq -r '.uuid'
          )
        fi
        # We need to match both the name of the node and its IP to avoid matching a duplicate within the same tenant
        if [[ -z $HOSTID ]]; then
          echo "coult not get Node ID $HOSTID."
          exit 0
          #Check if response is a UUID
        elif [[ $HOSTID =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
          echo "$HOSTID"
        else
          echo "could not find uuid"
          exit 1
        fi
        }

      function force_remove(){
        echo "Sending force remove to Resource Manager"
        REMOVE_NODE=$(curl -s -X DELETE\
          -H "X-AUTH-TOKEN: $X_AUTH_TOKEN" \
          $RSMGR_URL/$HOSTID
        )
        echo $REMOVE_NODE
      }


      function get_cluster_nodes(){
        CLUSTER_STATE=$(curl -s -X GET\
          -H "X-AUTH-TOKEN: $X_AUTH_TOKEN" \
          $QBERT_URL/$CLUSTER_PROJECT_ID/clusters/$CLUSTER_ID/k8sapi/api/v1/nodes
        )
      }

      function wait_node_detach(){
          start=$EPOCHSECONDS
          while true; do
            #Query the API for the node state
            get_cluster_nodes

            NODE_STATE=$(echo $CLUSTER_STATE | jq '.items | any(.status.addresses[0].address == '\"$node_ip\"')')

            if [[ $NODE_STATE == *"false"* ]]; then
              echo "The node $HOSTID is not in the cluster. State: $NODE_STATE"
              break
            elif [[ $NODE_STATE == *"true"* ]]; then
              echo "The node $HOSTID is still detaching. State: $NODE_STATE. Checking again in 10 seconds"
              sleep 10
            else
              echo "The node $HOSTID is somewhere. State: $NODE_STATE. Failed"
              break
            fi

            if (( EPOCHSECONDS-start > 600 )); then
              echo "timeout waiting for detach"
              break
            fi
          done
      }

      function get_nodes(){
        QBERT_URL="$pf9_account_url/qbert/v4"

        # We need to match both the name of the node and its IP to avoid matching a duplicate within the same tenant
        DU_NODES=$(curl -s \
          -H "X-AUTH-TOKEN: $X_AUTH_TOKEN" \
          $QBERT_URL/$PROJECT_UUID/nodes
        )
      }

      function wait_node(){
          while true; do
            #Query the API for the node state
            get_nodes

            NODE=$(echo $DU_NODES | jq '. | any(.uuid == '\"$HOSTID\"')')

            if [[ $NODE == *"false"* ]]; then
              echo "The node $HOSTID is not in the DU. State: $NODE"
              break
            elif [[ $NODE == *"true"* ]]; then
              echo "The node $HOSTID is still unauthorizing. State: $NODE. Checking again in 10 seconds"
              sleep 10
            else
              echo "The node $HOSTID is somewhere. State: $NODE. Failed"
              break
            fi
          done
      }


      function check_node_rsmgr(){
                echo "Checking Resource Manager for the node"
        NODE_STATE=$(curl -s -X GET\
          -H "X-AUTH-TOKEN: $X_AUTH_TOKEN" \
          $RSMGR_URL/$HOSTID | jq -r '.role_status'
        )
      }

      function wait_node_rsmgr(){
          start=$EPOCHSECONDS
          while true; do
            #Query the API for the node state
            check_node_rsmgr
            if [[ $NODE_STATE == *"ok"* ]]; then
              echo "The node $HOSTID is in OK state. State: $NODE_STATE"
              break
            elif [[ $NODE_STATE == *"converging"* ]]; then
              echo "The node $HOSTID is still converging. State: $NODE_STATE. Checking again in 10 seconds"
              sleep 10
            elif [[ $NODE_STATE == *"failed"* ]]; then
              echo "The node $HOSTID failed to onboard. State: $NODE_STATE"
              break
            elif [[ $NODE_STATE == *"error"* ]]; then
              echo "The node $HOSTID is not ready. State: $NODE_STATE. Checking again in 10 seconds"
              break
            else
              echo "The node $HOSTID is somewhere. State: $NODE_STATE. Checking again in 10 seconds"
              break
            fi
            if (( EPOCHSECONDS-start > 600 )); then
              echo "timeout waiting for detach"
              break
            fi
          done
      }



      get_token
      get_node_id

      pf9ctl config set --no-prompt --account-url $pf9_account_url --password $pf9_password --username $pf9_username --tenant $pf9_tenant --region $pf9_region

      wait_node_rsmgr
      if [[ -z $CLUSTER_ID ]]; then
        force_remove

      else 
        pf9ctl detach-node --no-prompt
        wait_node_detach 
        pf9ctl decommission-node
      fi
        
      force_remove
    path: /root/remove_node.sh
    permissions: '0754'
    owner: root:root
%{else}
  - content: |
      #!/bin/bash
      echo "Add script if needed"
    path: /root/remove_node.sh
    permissions: '0754'
    owner: root:root
%{endif~}
  - content: |
      net.bridge.bridge-nf-call-iptables=1
      vm.overcommit_memory=1
      kernel.panic=10
      kernel.panic_on_oops=1
      fs.inotify.max_user_watches=65536
    path: /etc/sysctl.d/k8s.conf
    permissions: '0644'
    owner: root:root
  - content: |
      iptable_filter
      ip_set_hash_net
      iptable_mangle
      iptable_raw
      veth
      vxlan
      x_tables
      xt_comment
      xt_mark
      xt_multiport
      xt_nat
      xt_recent
      xt_set
      xt_statistic
      xt_tcpudp
    path: /etc/modules-load.d/cloud-init-modules.conf
    permissions: '0644'
    owner: root:root
  - content: |
      [Time]
      NTP=${ntp_servers[0]}
      FallbackNTP=${ntp_servers[1]}
      #RootDistanceMaxSec=5
      #PollIntervalMinSec=32
      #PollIntervalMaxSec=2048
      #ConnectionRetrySec=30
      #SaveIntervalSec=60
    path: /etc/systemd/timesyncd.conf
    permissions: '0644'
    owner: root:root
  - content: ${filebase64("${filepath}/create-restart-flag.sh")}
    path: /root/create-restart-flag.sh
    permissions: '0755'
    owner: root:root
    encoding: "base64"
  - owner: root:root
    path: /etc/cron.d/check-for-restart
    content: |
      0 2 * * * root /root/create-restart-flag.sh
