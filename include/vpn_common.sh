#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

Vpn_Gen_Password() {
  local len=${1:-16}
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -base64 48 | tr -dc 'A-Za-z0-9' | head -c ${len}
  else
    tr -dc 'A-Za-z0-9' < /dev/urandom | head -c ${len}
  fi
}

Vpn_Check_Port_In_Use() {
  local port=$1
  local proto=$2
  if [ "${proto}" == 'udp' ]; then
    ss -lun 2>/dev/null | awk '{print $5}' | grep -qE ":${port}$"
  else
    ss -lnt 2>/dev/null | awk '{print $4}' | grep -qE ":${port}$"
  fi
}

Vpn_Check_Ports() {
  local failed=0
  for item in "tcp:${vpn_https_port}" "tcp:${vpn_mgmt_port}" "udp:${vpn_openvpn_port}"; do
    local proto=${item%%:*}
    local port=${item##*:}
    if Vpn_Check_Port_In_Use ${port} ${proto}; then
      echo "${CFAILURE}Port ${port}/${proto} is already in use!${CEND}"
      failed=1
    fi
  done
  for p in 80 443; do
    if Vpn_Check_Port_In_Use ${p} tcp; then
      echo "${CWARNING}Warning: TCP ${p} is used by web service (VPN will not use it).${CEND}"
    fi
  done
  [ ${failed} -eq 1 ] && return 1
  return 0
}

Vpn_Enable_Ip_Forward() {
  cat > /etc/sysctl.d/99-oneinstack-vpn.conf << EOF
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
  sysctl -p /etc/sysctl.d/99-oneinstack-vpn.conf >/dev/null 2>&1
}

Vpn_Disable_Ip_Forward() {
  rm -f /etc/sysctl.d/99-oneinstack-vpn.conf
}

Vpn_Open_Firewall_Ports() {
  if [ "${PM}" == 'yum' ]; then
    if systemctl is-active firewalld >/dev/null 2>&1; then
      firewall-cmd --permanent --add-port=${vpn_https_port}/tcp >/dev/null 2>&1
      firewall-cmd --permanent --add-port=${vpn_mgmt_port}/tcp >/dev/null 2>&1
      firewall-cmd --permanent --add-port=${vpn_openvpn_port}/udp >/dev/null 2>&1
      firewall-cmd --reload >/dev/null 2>&1
    fi
  elif [ "${PM}" == 'apt-get' ]; then
    if command -v ufw >/dev/null 2>&1; then
      ufw allow ${vpn_https_port}/tcp >/dev/null 2>&1
      ufw allow ${vpn_mgmt_port}/tcp >/dev/null 2>&1
      ufw allow ${vpn_openvpn_port}/udp >/dev/null 2>&1
    fi
  fi
}

Vpn_Close_Firewall_Ports() {
  if [ "${PM}" == 'yum' ]; then
    if systemctl is-active firewalld >/dev/null 2>&1; then
      firewall-cmd --permanent --remove-port=${vpn_https_port}/tcp >/dev/null 2>&1
      firewall-cmd --permanent --remove-port=${vpn_mgmt_port}/tcp >/dev/null 2>&1
      firewall-cmd --permanent --remove-port=${vpn_openvpn_port}/udp >/dev/null 2>&1
      firewall-cmd --reload >/dev/null 2>&1
    fi
  elif [ "${PM}" == 'apt-get' ]; then
    if command -v ufw >/dev/null 2>&1; then
      ufw delete allow ${vpn_https_port}/tcp >/dev/null 2>&1
      ufw delete allow ${vpn_mgmt_port}/tcp >/dev/null 2>&1
      ufw delete allow ${vpn_openvpn_port}/udp >/dev/null 2>&1
    fi
  fi
}

Vpn_Install_Systemd() {
  cat > /lib/systemd/system/vpnserver.service << EOF
[Unit]
Description=SoftEther VPN Server
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
WorkingDirectory=${vpn_install_dir}
ExecStart=${vpn_install_dir}/vpnserver start
ExecStop=${vpn_install_dir}/vpnserver stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable vpnserver >/dev/null 2>&1
}

Vpn_Remove_Systemd() {
  systemctl stop vpnserver >/dev/null 2>&1
  systemctl disable vpnserver >/dev/null 2>&1
  rm -f /lib/systemd/system/vpnserver.service
  systemctl daemon-reload
}

Vpn_Is_Installed() {
  [ -e "${vpn_install_dir}/vpnserver" ] && [ -e "${vpn_install_dir}/vpncmd" ]
}
