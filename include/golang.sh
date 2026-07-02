#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

Map_Golang_Ver() {
  case "${golang_option}" in
    1)
      golang_ver=${golang126_ver}
      ;;
    2)
      golang_ver=${golang125_ver}
      ;;
    3)
      golang_ver=${golang124_ver}
      ;;
    4)
      golang_ver=${golang123_ver}
      ;;
    5)
      golang_ver=${golang122_ver}
      ;;
    6)
      golang_ver=${golang121_ver}
      ;;
    *)
      golang_ver=${golang_ver:-${golang125_ver}}
      ;;
  esac
}

Clean_Golang_Install() {
  [ -d "${g_install_dir}" ] && rm -rf ${g_install_dir}
  [ -d "${golang_install_dir}" ] && rm -rf ${golang_install_dir}
  [ -e /etc/profile.d/golang.sh ] && rm -f /etc/profile.d/golang.sh
}

Install_Golang_With_G() {
  pushd ${oneinstack_dir}/src > /dev/null

  Clean_Golang_Install

  mkdir -p ${g_install_dir}/{bin,downloads,versions}
  tar xzf g${g_ver}.linux-${SYS_ARCH}.tar.gz -C ${g_install_dir}/bin
  chmod +x ${g_install_dir}/bin/g

  [ "${OUTIP_STATE}"x == "China"x ] && G_MIRROR=https://golang.google.cn/dl/ || G_MIRROR=https://go.dev/dl/
  mkdir -p ${gopath_dir}
  cat > /etc/profile.d/golang.sh << EOF
# g golang version manager
export G_HOME=${g_install_dir}
export G_EXPERIMENTAL=true
export GOROOT=\${G_HOME}/go
export GOPATH=${gopath_dir}
export G_MIRROR=${G_MIRROR}
export PATH=\${G_HOME}/bin:\${GOROOT}/bin:\${GOPATH}/bin:\$PATH
EOF
  . /etc/profile.d/golang.sh

  if [ -n "${golang_ver}" ]; then
    echo "${CMSG}Installing Go ${golang_ver} via g...${CEND}"
    g install ${golang_ver}
    g use ${golang_ver}
  fi

  if command -v go >/dev/null 2>&1; then
    echo "${CSUCCESS}Golang ($(go version)) installed successfully via g! ${CEND}"
    echo "${CMSG}Use 'g ls' to list versions, 'g install <ver>' to add more, 'g use <ver>' to switch.${CEND}"
  else
    echo "${CFAILURE}Golang install failed, Please contact the author! ${CEND}" && grep -Ew 'NAME|ID|ID_LIKE|VERSION_ID|PRETTY_NAME' /etc/os-release
    kill -9 $$; exit 1;
  fi
  popd > /dev/null
}

Install_Golang_Binary() {
  pushd ${oneinstack_dir}/src > /dev/null

  Clean_Golang_Install

  tar xzf go${golang_ver}.linux-${SYS_ARCH}.tar.gz
  /bin/mv go ${golang_install_dir}

  mkdir -p ${gopath_dir}
  cat > /etc/profile.d/golang.sh << EOF
export GOROOT=${golang_install_dir}
export GOPATH=${gopath_dir}
export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH
EOF
  . /etc/profile.d/golang.sh

  if [ -e "${golang_install_dir}/bin/go" ]; then
    echo "${CSUCCESS}Golang ($(go version)) installed successfully! ${CEND}"
  else
    echo "${CFAILURE}Golang install failed, Please contact the author! ${CEND}" && grep -Ew 'NAME|ID|ID_LIKE|VERSION_ID|PRETTY_NAME' /etc/os-release
    kill -9 $$; exit 1;
  fi
  popd > /dev/null
}

Install_Golang() {
  case "${golang_method_option}" in
    2)
      Install_Golang_Binary
      ;;
    *)
      Install_Golang_With_G
      ;;
  esac
}

Uninstall_Golang() {
  if [ -e "${g_install_dir}/bin/g" ] || [ -e "${golang_install_dir}/bin/go" ] || [ -e /etc/profile.d/golang.sh ]; then
    rm -rf ${g_install_dir} ${golang_install_dir} /etc/profile.d/golang.sh
    echo "${CMSG}Golang uninstall completed! ${CEND}"
  fi
}
