#cloud-config
%{if ca_certificates != ""~}
ca-certs:
  trusted:
  - |
   ${indent(3, ca_certificates)}
%{endif~}
sudo: ["ALL=(ALL) NOPASSWD:ALL"]
package_update: true
package_upgrade: true
packages:
  - apt-transport-https
  - ca-certificates
  - curl
  - gnupg-agent
  - software-properties-common
power_state:
  mode: reboot
runcmd:
  - modprobe br_netfilter
  - systemctl restart systemd-modules-load
  - systemctl restart chronyd
  - sysctl -w net.bridge.bridge-nf-call-iptables=1
  - sysctl -w vm.overcommit_memory=1
  - sysctl -w kernel.panic=10
  - sysctl -w kernel.panic_on_oops=1
  - sudo /bin/systemctl reload sshd.service
  - curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  - add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"
  - apt-get update -y
users:
  - default
  - name: ${ssh_user}
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys:
%{for key in ssh_authorized_keys~}
      - ${key}
%{endfor~}
write_files:
  - content: |
      net.bridge.bridge-nf-call-iptables=1
      vm.overcommit_memory=1
      kernel.panic=10
      kernel.panic_on_oops=1
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
      # Use public servers from the pool.ntp.org project.
      # Please consider joining the pool (http://www.pool.ntp.org/join.html).
%{for server in ntp_servers~}
      server ${server}
%{endfor~}

      # Record the rate at which the system clock gains/losses time.
      driftfile /var/lib/chrony/drift

      # Allow the system clock to be stepped in the first three updates
      # if its offset is larger than 1 second.
      makestep 1.0 3

      # Enable kernel synchronization of the real-time clock (RTC).
      rtcsync

      # Enable hardware timestamping on all interfaces that support it.
      #hwtimestamp *

      # Increase the minimum number of selectable sources required to adjust
      # the system clock.
      #minsources 2

      # Allow NTP client access from local network.
      #allow 192.168.0.0/16

      # Serve time even if not synchronized to a time source.
      #local stratum 10

      # Specify file containing keys for NTP authentication.
      #keyfile /etc/chrony.keys

      # Specify directory for log files.
      logdir /var/log/chrony

      # Select which information is logged.
      #log measurements statistics tracking
    path: /etc/chrony.conf
    permissions: '0644'
    owner: root:root
  - content: |
      # Logrotate for all containers
      # * rotate the log file if its size is > ${logrotate_size} OR if 1
      # * day has elapsed save rotated logs into a gzipped timestamped backup
      # * log file timestamp (controlled by 'dateformat') includes seconds too. This
      #   ensures that logrotate can generate unique logfiles during each rotation
      #   (otherwise it skips rotation if 'maxsize' is reached multiple times in a
      #   day).
      # * keep only ${logrotate_keep_old} old (rotated) logs, and will discard 
      #   older logs.
      /var/lib/docker/containers/*/*.log {
        rotate ${logrotate_keep_old}
        copytruncate
        missingok
        notifempty
        compress
        size ${logrotate_size}
        daily
        dateext
        dateformat -%Y%m%d
        create 0644 root root
      }
    path: /etc/logrotate.d/containerlogs
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
%{if docker_registry != ""~}
  - content: |
      {
        "insecure-registries": ["${docker_registry}"]
      }
    path: /etc/docker/daemon.json
    permissions: '0644'
    owner: root:root
%{endif~}