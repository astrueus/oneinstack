#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

. ./include/vpn_common.sh
. ./include/vpn_softether.sh
. ./include/vpn_wireguard.sh
. ./include/vpn_openvpn.sh

Vpn_Set_Defaults() {
  [ -z "${vpn_type}" ] && vpn_type=1
  [ -z "${softether_option}" ] && softether_option=4
  [ -z "${vpn_config_mode}" ] && vpn_config_mode=1
  [ -z "${vpn_openvpn_port}" ] && vpn_openvpn_port=1194
  [ -z "${vpn_https_port}" ] && vpn_https_port=18443
  [ -z "${vpn_mgmt_port}" ] && vpn_mgmt_port=20555
  [ -z "${vpn_hub_name}" ] && vpn_hub_name=DEFAULT
  [ -z "${vpn_user_name}" ] && vpn_user_name=vpnuser
}

Vpn_Select_Type() {
  while :; do
    echo
    echo 'Please select VPN product:'
    echo -e "\t${CMSG}1${CEND}. SoftEther VPN Server"
    echo -e "\t${CMSG}2${CEND}. WireGuard (coming soon)"
    echo -e "\t${CMSG}3${CEND}. OpenVPN (coming soon)"
    read -e -p "Please input a number:(Default 1 press Enter) " vpn_type
    vpn_type=${vpn_type:-1}
    if [[ ${vpn_type} =~ ^[1-3]$ ]]; then
      break
    else
      echo "${CWARNING}input error! Please only input number 1~3${CEND}"
    fi
  done
}

Vpn_Select_SoftEther_Version() {
  while :; do
    echo
    echo 'Please select SoftEther version (low to high):'
    echo -e "\t${CMSG}1${CEND}. v${softether438_rtm_ver} (Stable)"
    echo -e "\t${CMSG}2${CEND}. v${softether441_rtm_ver} (Stable)"
    echo -e "\t${CMSG}3${CEND}. v${softether442_rtm_ver} (Stable)"
    echo -e "\t${CMSG}4${CEND}. v${softether444_rtm_ver} (Stable, recommended)"
    echo -e "\t${CMSG}5${CEND}. v${softether501_ver} (Developer, experimental)"
    echo -e "\t${CMSG}6${CEND}. v${softether502_ver} (Developer, experimental)"
    read -e -p "Please input a number:(Default 4 press Enter) " softether_option
    softether_option=${softether_option:-4}
    if [[ ${softether_option} =~ ^[1-6]$ ]]; then
      break
    else
      echo "${CWARNING}input error! Please only input number 1~6${CEND}"
    fi
  done
}

Vpn_Select_Config_Mode() {
  while :; do
    echo
    echo 'Please select configuration mode:'
    echo -e "\t${CMSG}1${CEND}. Install only (manual vpncmd setup)"
    echo -e "\t${CMSG}2${CEND}. Auto configure Hub, user and ports"
    read -e -p "Please input a number:(Default 1 press Enter) " vpn_config_mode
    vpn_config_mode=${vpn_config_mode:-1}
    if [[ ${vpn_config_mode} =~ ^[1-2]$ ]]; then
      break
    else
      echo "${CWARNING}input error! Please only input number 1~2${CEND}"
    fi
  done
}

Vpn_Prompt_Ports() {
  echo
  read -e -p "OpenVPN UDP port (Default ${vpn_openvpn_port}): " _port
  [ -n "${_port}" ] && vpn_openvpn_port=${_port}
  read -e -p "SoftEther HTTPS port, not 443 (Default ${vpn_https_port}): " _port
  [ -n "${_port}" ] && vpn_https_port=${_port}
  read -e -p "Management port (Default ${vpn_mgmt_port}): " _port
  [ -n "${_port}" ] && vpn_mgmt_port=${_port}
  if [ "${vpn_config_mode}" == '2' ]; then
    read -e -p "Hub name (Default ${vpn_hub_name}): " _hub
    [ -n "${_hub}" ] && vpn_hub_name=${_hub}
    read -e -p "VPN username (Default ${vpn_user_name}): " _user
    [ -n "${_user}" ] && vpn_user_name=${_user}
  fi
}

Vpn_Interactive_Options() {
  Vpn_Set_Defaults
  Vpn_Select_Type
  if [ "${vpn_type}" == '1' ]; then
    Vpn_Select_SoftEther_Version
    Vpn_Select_Config_Mode
    Vpn_Prompt_Ports
  fi
}

Install_Vpn() {
  Vpn_Set_Defaults
  case "${vpn_type}" in
    1)
      Install_SoftEther
      ;;
    2)
      Install_WireGuard
      ;;
    3)
      Install_OpenVPN
      ;;
    *)
      echo "${CFAILURE}Unknown vpn_type: ${vpn_type}${CEND}"
      ;;
  esac
}

Uninstall_Vpn() {
  Vpn_Set_Defaults
  case "${vpn_type}" in
    1)
      Uninstall_SoftEther
      ;;
    2)
      Uninstall_WireGuard
      ;;
    3)
      Uninstall_OpenVPN
      ;;
    *)
      echo "${CFAILURE}Unknown vpn_type: ${vpn_type}${CEND}"
      ;;
  esac
}
