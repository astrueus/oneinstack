#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

Map_SoftEther_Ver() {
  case "${softether_option}" in
    1)
      softether_ver=${softether438_rtm_ver}
      softether_repo=stable
      ;;
    2)
      softether_ver=${softether441_rtm_ver}
      softether_repo=stable
      ;;
    3)
      softether_ver=${softether442_rtm_ver}
      softether_repo=stable
      ;;
    4)
      softether_ver=${softether444_rtm_ver}
      softether_repo=stable
      ;;
    5)
      softether_ver=${softether501_ver}
      softether_repo=developer
      ;;
    6)
      softether_ver=${softether502_ver}
      softether_repo=developer
      ;;
    *)
      softether_ver=${softether444_rtm_ver}
      softether_repo=stable
      ;;
  esac
}

Get_SoftEther_Arch() {
  if [ "${SYS_ARCH}" == 'arm64' ]; then
    echo linux-arm64-64bit
  else
    echo linux-x64-64bit
  fi
}

Get_SoftEther_Release_Tag() {
  if [ "${softether_repo}" == 'stable' ]; then
    echo "v${softether_ver}"
  else
    echo "${softether_ver}"
  fi
}

Get_SoftEther_Github_Repo() {
  if [ "${softether_repo}" == 'stable' ]; then
    echo SoftEtherVPN/SoftEtherVPN_Stable
  else
    echo SoftEtherVPN/SoftEtherVPN
  fi
}

Get_SoftEther_Download_Url() {
  local repo tag arch api_json url
  Map_SoftEther_Ver
  repo=$(Get_SoftEther_Github_Repo)
  tag=$(Get_SoftEther_Release_Tag)
  arch=$(Get_SoftEther_Arch)

  api_json=$(curl --connect-timeout 10 -m 30 -sL "https://api.github.com/repos/${repo}/releases/tags/${tag}")
  url=$(echo "${api_json}" | grep -oE 'https://[^"]+softether-vpnserver[^"]+'"${arch}"'[^"]+\.tar\.gz' | head -1)

  if [ -n "${url}" ]; then
    echo "${url}"
    return 0
  fi

  if [ "${softether_repo}" == 'developer' ]; then
    return 1
  fi

  return 1
}

Show_SoftEther_Manual_Hint() {
  echo
  echo "${CSUCCESS}SoftEther VPN Server installed successfully!${CEND}"
  echo "${CMSG}Install dir: ${vpn_install_dir}${CEND}"
  echo "${CMSG}Manage: ${vpn_install_dir}/vpncmd localhost /SERVER${CEND}"
  echo "${CMSG}Service: systemctl {start|stop|restart|status} vpnserver${CEND}"
  echo "${CMSG}Ports (custom, not 443): OpenVPN UDP ${vpn_openvpn_port}, HTTPS ${vpn_https_port}, Mgmt ${vpn_mgmt_port}${CEND}"
  echo
  echo "Manual setup with vpncmd:"
  echo "  1. HubCreate ${vpn_hub_name} /PASSWORD:<hub_password>"
  echo "  2. UserCreate <username> /GROUP:none /REALNAME:none /NOTE:none"
  echo "  3. UserPasswordSet <username> /PASSWORD:<password> /TYPE:raw"
  echo "  4. Configure listeners (avoid TCP 443, use UDP ${vpn_openvpn_port})"
  echo "  5. SecureNatEnable (if clients need Internet access)"
  echo
}

Configure_SoftEther_Auto() {
  local hub=${vpn_hub_name:-DEFAULT}
  local user=${vpn_user_name:-vpnuser}
  local server_pass hub_pass user_pass vpncmd_in vpncmd_out

  if [ "${softether_repo}" == 'developer' ]; then
    echo "${CWARNING}Auto configuration is only fully tested on Stable Edition 4.x.${CEND}"
    echo "${CWARNING}Developer Edition 5.x: use manual vpncmd or minimal setup.${CEND}"
    Show_SoftEther_Manual_Hint
    return
  fi

  server_pass=$(Vpn_Gen_Password 16)
  hub_pass=$(Vpn_Gen_Password 16)
  user_pass=$(Vpn_Gen_Password 12)
  vpncmd_in=/tmp/softether_vpncmd_$$.in
  vpncmd_out=/tmp/softether_vpncmd_$$.out

  sleep 3

  cat > ${vpncmd_in} << EOF
HubCreate ${hub} /PASSWORD:${hub_pass}
Hub ${hub}
SecureNatEnable
UserCreate ${user} /GROUP:none /REALNAME:none /NOTE:none
UserPasswordSet ${user} /PASSWORD:${user_pass} /TYPE:raw
ServerPasswordSet ${server_pass}
ListenerDelete 443
ListenerCreate ${vpn_https_port}
OpenVpnEnable enable
Flush
EOF

  ${vpn_install_dir}/vpncmd localhost /SERVER /IN:${vpncmd_in} /OUT:${vpncmd_out} >/dev/null 2>&1

  cat > ${vpn_credentials_file} << EOF
# SoftEther VPN credentials - keep secret
edition=${softether_repo}
version=${softether_ver}
hub=${hub}
server_admin_password=${server_pass}
hub_admin_password=${hub_pass}
vpn_username=${user}
vpn_password=${user_pass}
openvpn_udp_port=${vpn_openvpn_port}
https_port=${vpn_https_port}
mgmt_port=${vpn_mgmt_port}
vpncmd=${vpn_install_dir}/vpncmd localhost /SERVER /PASSWORD:${server_pass}
# Set OpenVPN UDP port ${vpn_openvpn_port} in Server Manager if not applied automatically
EOF
  chmod 600 ${vpn_credentials_file}

  rm -f ${vpncmd_in} ${vpncmd_out}

  echo
  echo "${CSUCCESS}SoftEther VPN Server auto-configured successfully!${CEND}"
  echo "${CMSG}Credentials saved to: ${vpn_credentials_file} (chmod 600)${CEND}"
  echo "${CMSG}Hub: ${hub}  User: ${user}${CEND}"
  echo "${CMSG}OpenVPN UDP: ${vpn_openvpn_port}  HTTPS: ${vpn_https_port}  Mgmt: ${vpn_mgmt_port}${CEND}"
  echo "${CMSG}Service: systemctl {start|stop|restart|status} vpnserver${CEND}"
  echo
}

Install_SoftEther() {
  Map_SoftEther_Ver

  if Vpn_Is_Installed; then
    echo "${CWARNING}SoftEther VPN Server already installed at ${vpn_install_dir}! ${CEND}"
    return
  fi

  if [ "${softether_repo}" == 'developer' ]; then
    echo "${CWARNING}Developer Edition (5.x) may be unstable. Stable 4.x is recommended for production.${CEND}"
  fi

  if ! Vpn_Check_Ports; then
    kill -9 $$; exit 1;
  fi

  local download_url softether_tar extract_dir
  download_url=$(Get_SoftEther_Download_Url)
  if [ -z "${download_url}" ]; then
    echo "${CFAILURE}Failed to resolve SoftEther download URL for ${softether_ver}.${CEND}"
    if [ "${softether_repo}" == 'developer' ]; then
      echo "${CWARNING}Developer Edition has no prebuilt Linux vpnserver package on GitHub.${CEND}"
      echo "${CMSG}Please use Stable Edition 4.x (softether_option 1-4).${CEND}"
    fi
    kill -9 $$; exit 1;
  fi

  pushd ${oneinstack_dir}/src > /dev/null
  softether_tar=${download_url##*/}
  src_url=${download_url} && Download_src

  rm -rf ${vpn_install_dir}
  tar zxf ${softether_tar}
  if [ -f ./vpnserver/vpnserver ]; then
    /bin/mv vpnserver ${vpn_install_dir}
  else
    extract_dir=$(find . -maxdepth 2 -type f -name vpnserver 2>/dev/null | head -1)
    if [ -n "${extract_dir}" ]; then
      /bin/mv "$(dirname ${extract_dir})" ${vpn_install_dir}
    else
      echo "${CFAILURE}SoftEther package layout not recognized.${CEND}"
      kill -9 $$; exit 1;
    fi
  fi

  chmod +x ${vpn_install_dir}/vpnserver ${vpn_install_dir}/vpncmd
  rm -f ${softether_tar}
  popd > /dev/null

  if ! Vpn_Is_Installed; then
    echo "${CFAILURE}SoftEther install failed!${CEND}" && grep -Ew 'NAME|ID|ID_LIKE|VERSION_ID|PRETTY_NAME' /etc/os-release
    kill -9 $$; exit 1;
  fi

  mkdir -p ${vpn_config_dir}
  Vpn_Enable_Ip_Forward
  Vpn_Open_Firewall_Ports
  Vpn_Install_Systemd
  systemctl start vpnserver

  if [ "${vpn_config_mode}" == '2' ]; then
    Configure_SoftEther_Auto
  else
    Show_SoftEther_Manual_Hint
  fi
}

Uninstall_SoftEther() {
  if ! Vpn_Is_Installed && [ ! -e /lib/systemd/system/vpnserver.service ]; then
    echo "${CWARNING}SoftEther VPN Server is not installed! ${CEND}"
    return
  fi

  Vpn_Remove_Systemd
  Vpn_Close_Firewall_Ports
  Vpn_Disable_Ip_Forward
  rm -rf ${vpn_install_dir} ${vpn_config_dir}
  if [ -e "${vpn_credentials_file}" ]; then
    rm -f ${vpn_credentials_file}
  fi
  echo "${CMSG}SoftEther VPN Server uninstall completed!${CEND}"
}
