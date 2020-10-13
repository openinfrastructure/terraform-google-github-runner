# cloud-config
users:
  - name: github-runner
    shell: /bin/bash
    uid: 2000
    groups:
      - docker

write_files:
  - path: /var/lib/cloud/bin/firewall
    permissions: 0755
    owner: root
    content: |
      #! /bin/bash
      iptables -w -A INPUT -p tcp --dport ${hc_port} -j ACCEPT
  - path: /var/run/github-runner-register
    permissions: 0600
    owner: root
    content: |
      REGISTRATION_TOKEN=${registration_token}
  - path: /etc/systemd/system/github-runner-register.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=GitHub Runner Registration/Unregistration
      ConditionFileIsExecutable=/var/lib/google/bin/github-runner
      After=syslog.target network-online.target
      [Service]
      EnvironmentFile=/var/run/github-runner-register
      Type=oneshot
      RemainAfterExit=yes
      # ExecStart=
      # ExecStop=
      [Install]
      WantedBy=multi-user.target
  - path: /etc/systemd/system/github-runner.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Github Runner
      # ConditionFileIsExecutable=/var/lib/google/bin/gitlab-runner
      After=github-runner-register.service syslog.target network-online.target
      Requires=github-runner-register.service
      [Service]
      StartLimitInterval=5
      StartLimitBurst=10
      # ExecStart=/var/lib/google/bin/github-runner "run" "--working-directory" "/home/gitlab-runner" "--config" "/etc/gitlab-runner/config.toml" "--service" "gitlab-runner" "--syslog" "--user" "gitlab-runner"
      Restart=always
      RestartSec=120
      [Install]
      WantedBy=multi-user.target
  - path: /etc/systemd/system/firewall.service
    permissions: 0644
    owner: root
    content: |
      [Unit]
      Description=Host firewall configuration
      ConditionFileIsExecutable=/var/lib/cloud/bin/firewall
      After=network-online.target
      [Service]
      ExecStart=/var/lib/cloud/bin/firewall
      Type=oneshot
      [Install]
      WantedBy=multi-user.target

runcmd:
  - mkdir /var/lib/google/tmp
  - mkdir /var/lib/google/bin
  - mkdir /var/lib/google/actions-runner
  - curl -L --output /var/lib/google/tmp/actions-runner.tgz ${github-runner-url}
  - (cd /var/lib/google/actions-runner && tar -xzf /var/lib/google/tmp/actions-runner.tgz)
  - (cd /var/lib/google/actions-runner && ./config.sh --url ${github-url} --token ${registration_token}
  - systemctl daemon-reload
  - systemctl start firewall.service
