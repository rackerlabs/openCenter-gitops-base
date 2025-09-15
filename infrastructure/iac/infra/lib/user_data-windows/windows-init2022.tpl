#cloud-config
# Windows Cloud-Init Configuration

%{if ca_certificates != ""~}
ca_certs:
  trusted:
  - |
   ${indent(3, ca_certificates)}
%{endif~}

# Set timezone and locale
timezone: UTC
locale: en-US

# Configure WinRM for remote management
winrm:
  listeners:
    - Protocol: HTTP
      Port: 5985
      Enabled: true
    - Protocol: HTTPS
      Port: 5986
      Enabled: true
  service:
    AllowUnencrypted: true
    Auth:
      Basic: true
      Kerberos: true
      Negotiate: true
      Certificate: false
      CredSSP: false

# Windows Updates
updates:
  network:
    when: ['instance-first-boot']

%{if reboot == true~}
power_state:
  delay: 30
  mode: reboot
  message: "Rebooting after cloud-init setup"
  timeout: 30
  condition: true
%{endif~}

# Create users
users:
  - name: ${windows_user}
    passwd: ${windows_admin_password}
    primary_group: Administrators
    groups: [Administrators, "Remote Desktop Users"]
    inactive: false
    expiredate: 2099-12-31

# Install packages via Chocolatey
packages:
  - curl
  - jq
  - powershell-core
  - openssh

write_files:
  - path: C:\ProgramData\ssh\administrators_authorized_keys
    content: |
%{ for key in ssh_authorized_keys ~}
      ${key}
%{ endfor ~}
    encoding: ascii
    permissions: '0600'
  - path: C:\Users\${windows_user}\.ssh\authorized_keys
    content: |
%{ for key in ssh_authorized_keys ~}
      ${key}
%{ endfor ~}
    encoding: ascii
    permissions: '0600'

# Run commands (PowerShell)
runcmd:
  # Install and configure OpenSSH Server
  - 'powershell.exe -Command "Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0"'
  - 'powershell.exe -Command "Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0"'
  - 'powershell.exe -Command "Set-WsManQuickConfig -Force"'
  
  # Start and enable SSH service
  - 'powershell.exe -Command "Start-Service sshd"'
  - 'powershell.exe -Command "Set-Service -Name sshd -StartupType Automatic"'
  - 'powershell.exe -Command "Start-Service ssh-agent"'
  - 'powershell.exe -Command "Set-Service -Name ssh-agent -StartupType Automatic"'
  
  # Configure networking and system settings
  # - 'powershell.exe -Command "Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False"'
  - 'powershell.exe -Command "New-NetFirewallRule -DisplayName "OpenSSH Server (sshd)" -Direction Inbound -Port 22 -Protocol TCP -Action Allow"'
  - 'powershell.exe -Command "New-NetFirewallRule -DisplayName "WinRM" -Direction Inbound -Port 5985 -Protocol TCP -Action Allow"'
  - 'powershell.exe -Command "Enable-PSRemoting -Force"'
  - 'powershell.exe -Command "Set-Item WSMan:\localhost\Client\TrustedHosts -Value \"*\" -Force"'
  
  # Create SSH directories and set permissions
  - 'powershell.exe -Command "New-Item -ItemType Directory -Force -Path \"C:\Users\${windows_user}\.ssh\""'
  - 'powershell.exe -Command "New-Item -ItemType Directory -Force -Path \"C:\ProgramData\ssh\""'
  
  # Set proper permissions for SSH files
  - 'powershell.exe -Command "icacls \"C:\ProgramData\ssh\administrators_authorized_keys\" /inheritance:r /grant \"Administrators:F\" /grant \"SYSTEM:F\""'
  - 'powershell.exe -Command "icacls \"C:\Users\${windows_user}\.ssh\authorized_keys\" /inheritance:r /grant \"${windows_user}:F\" /grant \"SYSTEM:F\""'
  - 'powershell.exe -Command "icacls \"C:\Users\${windows_user}\.ssh\" /inheritance:r /grant \"${windows_user}:F\" /grant \"SYSTEM:F\""'
  - 'powershell.exe -Command "icacls \"C:\ProgramData\ssh\sshd_config\" /inheritance:r /grant \"Administrators:F\" /grant \"SYSTEM:F\""'
  
  # Restart SSH service to apply configuration
  - 'powershell.exe -Command "Restart-Service sshd"'
  
  # Add hostname to hosts file (Windows equivalent)
  - 'powershell.exe -Command "$ip = (Invoke-RestMethod -Uri \"http://169.254.169.254/latest/meta-data/local-ipv4\"); $hostname = (Invoke-RestMethod -Uri \"http://169.254.169.254/latest/meta-data/hostname\").Split(\".\")[0]; Add-Content -Path \"C:\Windows\System32\drivers\etc\hosts\" -Value \"$ip $hostname\""'
  
  # Configure system settings for containerization
  - 'powershell.exe -Command "Enable-WindowsOptionalFeature -Online -FeatureName containers -All -NoRestart"'
  
  # Configure system parameters
  - 'powershell.exe -Command "Set-ItemProperty -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\" -Name \"OverCommitMemory\" -Value 1"'
  
  # Configure time synchronization
  - 'powershell.exe -Command "w32tm /config /manualpeerlist:\"${ntp_servers[0]},${ntp_servers[1]}\" /syncfromflags:manual /reliable:yes /update"'
  - 'powershell.exe -Command "Restart-Service w32time"'

# Final setup commands
final_message: |
  Windows node initialization completed.
  System may reboot if configured to do so.
  WinRM and SSH are enabled for remote management.
  SSH is available on port 22.