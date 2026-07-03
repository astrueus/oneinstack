#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

export PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/sbin:/usr/local/bin
clear
printf "
#######################################################################
#       OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+      #
#                    Install/Uninstall Extensions                     #
#       For more information please visit https://oneinstack.com      #
#######################################################################
"
# Check if user is root
# shellcheck disable=SC2046
[ $(id -u) != '0' ] && { echo "${CFAILURE}Error: You must be root to run this script${CEND}"; exit 1; }

oneinstack_dir=$(dirname "`readlink -f $0`")
# shellcheck disable=SC2164
pushd ${oneinstack_dir} > /dev/null

. ./versions.txt
. ./options.conf
. ./include/color.sh
. ./include/check_os.sh
. ./include/download.sh
. ./include/get_char.sh

. ./include/composer.sh

. ./include/fail2ban.sh

. ./include/ngx_lua_waf.sh

. ./include/zig.sh

. ./include/vpn.sh

# get the out ip country
OUTIP_STATE=$(./include/ois.${ARCH} ip_state)

# shellcheck disable=SC2154
Show_Help() {
  echo
  echo "Usage: $0  command ...
  --help, -h                  Show this help message
  --install, -i               Install
  --uninstall, -u             Uninstall
  --composer                  Composer
  --fail2ban                  Fail2ban
  --ngx_lua_waf               Ngx_lua_waf
  --zig                       Zig (C cross toolchain for Go CGO)
  --vpnserver                 SoftEther VPN Server / VPN addons
  --vpn_type [1-3]            1: SoftEther, 2: WireGuard, 3: OpenVPN
  --softether_option [1-6]    SoftEther version low to high (default 4: v4.44 RTM)
  --vpn_config_mode [1-2]       1: install only, 2: auto configure
  --vpn_openvpn_port PORT     OpenVPN UDP port (default 1194)
  --vpn_https_port PORT       SoftEther HTTPS port (default 18443)
  --vpn_mgmt_port PORT        Management port (default 20555)
  "
}

ARG_NUM=$#
TEMP=`getopt -o hiu --long help,install,uninstall,composer,fail2ban,ngx_lua_waf,zig,vpnserver,vpn_type:,softether_option:,vpn_config_mode:,vpn_openvpn_port:,vpn_https_port:,vpn_mgmt_port: -- "$@" 2>/dev/null`
[ $? != 0 ] && echo "${CWARNING}ERROR: unknown argument! ${CEND}" && Show_Help && exit 1
eval set -- "${TEMP}"
while :; do
  [ -z "$1" ] && break;
  case "$1" in
    -h|--help)
      Show_Help; exit 0
      ;;
    -i|--install)
      install_flag=y; shift 1
      ;;
    -u|--uninstall)
      uninstall_flag=y; shift 1
      ;;
    --composer)
      composer_flag=y; shift 1
      ;;
    --fail2ban)
      fail2ban_flag=y; shift 1
      ;;
    --ngx_lua_waf)
      ngx_lua_waf_flag=y; shift 1
      ;;
    --zig)
      zig_flag=y; shift 1
      ;;
    --vpnserver)
      vpnserver_flag=y; shift 1
      ;;
    --vpn_type)
      vpn_type=$2
      shift 2
      [[ ! ${vpn_type} =~ ^[1-3]$ ]] && {
        echo "${CWARNING}vpn_type input error! Please only input number 1~3${CEND}"
        exit 1
      }
      ;;
    --softether_option)
      softether_option=$2
      shift 2
      [[ ! ${softether_option} =~ ^[1-6]$ ]] && {
        echo "${CWARNING}softether_option input error! Please only input number 1~6${CEND}"
        exit 1
      }
      ;;
    --vpn_config_mode)
      vpn_config_mode=$2
      shift 2
      [[ ! ${vpn_config_mode} =~ ^[1-2]$ ]] && {
        echo "${CWARNING}vpn_config_mode input error! Please only input number 1~2${CEND}"
        exit 1
      }
      ;;
    --vpn_openvpn_port)
      vpn_openvpn_port=$2
      shift 2
      ;;
    --vpn_https_port)
      vpn_https_port=$2
      shift 2
      ;;
    --vpn_mgmt_port)
      vpn_mgmt_port=$2
      shift 2
      ;;
    --)
      shift
      ;;
    *)
      echo "${CWARNING}ERROR: unknown argument! ${CEND}" && Show_Help && exit 1
      ;;
  esac
done

ACTION_FUN() {
  while :; do
    echo
    echo "Please select an action:"
    echo -e "\t${CMSG}1${CEND}. install"
    echo -e "\t${CMSG}2${CEND}. uninstall"
    read -e -p "Please input a number:(Default 1 press Enter) " ACTION
    ACTION=${ACTION:-1}
    if [[ ! "${ACTION}" =~ ^[1,2]$ ]]; then
      echo "${CWARNING}input error! Please only input number 1~2${CEND}"
    else
      [ "${ACTION}" == '1' ] && install_flag=y
      [ "${ACTION}" == '2' ] && uninstall_flag=y
      break
    fi
  done
}

Menu() {
  while :;do
    printf "
What Are You Doing?
\t${CMSG}1${CEND}. Install/Uninstall PHP Composer
\t${CMSG}2${CEND}. Install/Uninstall fail2ban
\t${CMSG}3${CEND}. Install/Uninstall ngx_lua_waf
\t${CMSG}4${CEND}. Install/Uninstall Zig (PATH: ${zig_install_dir})
\t${CMSG}5${CEND}. Install/Uninstall VPN Server (PATH: ${vpn_install_dir})
\t${CMSG}q${CEND}. Exit
"
    read -e -p "Please input the correct option: " Number
    if [[ ! "${Number}" =~ ^[1-5,q]$ ]]; then
      echo "${CFAILURE}input error! Please only input 1~5 and q${CEND}"
    else
      case "${Number}" in
        1)
          ACTION_FUN
          if [ "${install_flag}" = 'y' ]; then
            Install_composer
          elif [ "${uninstall_flag}" = 'y' ]; then
            Uninstall_composer
          fi
          ;;
        2)
          ACTION_FUN
          if [ "${install_flag}" = 'y' ]; then
            Install_fail2ban
          elif [ "${uninstall_flag}" = 'y' ]; then
            Uninstall_fail2ban
          fi
          ;;
        3)
          ACTION_FUN
          if [ "${install_flag}" = 'y' ]; then
            # shellcheck disable=SC2154
            [ -e "${nginx_install_dir}/sbin/nginx" ] && Nginx_lua_waf
            # shellcheck disable=SC2154
            [ -e "${tengine_install_dir}/sbin/nginx" ] && Tengine_lua_waf
            enable_lua_waf
          elif [ "${uninstall_flag}" = 'y' ]; then
            disable_lua_waf
          fi
          ;;
        4)
          ACTION_FUN
          if [ "${install_flag}" = 'y' ]; then
            Install_Zig
          elif [ "${uninstall_flag}" = 'y' ]; then
            Uninstall_Zig
          fi
          ;;
        5)
          ACTION_FUN
          if [ "${install_flag}" = 'y' ]; then
            Vpn_Interactive_Options
            Install_Vpn
          elif [ "${uninstall_flag}" = 'y' ]; then
            Vpn_Set_Defaults
            Vpn_Select_Type
            Uninstall_Vpn
          fi
          ;;
        q)
          exit
          ;;
      esac
    fi
  done
}

if [ ${ARG_NUM} == 0 ]; then
  Menu
else
  if [ "${composer_flag}" == 'y' ]; then
    if [ "${install_flag}" = 'y' ]; then
      Install_composer
    elif [ "${uninstall_flag}" = 'y' ]; then
      Uninstall_composer
    fi
  fi
  if [ "${fail2ban_flag}" == 'y' ]; then
    if [ "${install_flag}" = 'y' ]; then
      Install_fail2ban
    elif [ "${uninstall_flag}" = 'y' ]; then
      Uninstall_fail2ban
    fi
  fi
  if [ "${ngx_lua_waf_flag}" == 'y' ]; then
    if [ "${install_flag}" = 'y' ]; then
      [ -e "${nginx_install_dir}/sbin/nginx" ] && Nginx_lua_waf
      [ -e "${tengine_install_dir}/sbin/nginx" ] && Tengine_lua_waf
      enable_lua_waf
    elif [ "${uninstall_flag}" = 'y' ]; then
      disable_lua_waf
    fi
  fi
  if [ "${zig_flag}" == 'y' ]; then
    if [ "${install_flag}" = 'y' ]; then
      Install_Zig
    elif [ "${uninstall_flag}" = 'y' ]; then
      Uninstall_Zig
    fi
  fi
  if [ "${vpnserver_flag}" == 'y' ]; then
    if [ "${install_flag}" = 'y' ]; then
      Install_Vpn
    elif [ "${uninstall_flag}" = 'y' ]; then
      Uninstall_Vpn
    fi
  fi
fi
