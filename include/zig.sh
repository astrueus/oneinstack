#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

Get_Zig_Arch() {
  if [ "${SYS_ARCH}" == 'arm64' ]; then
    echo aarch64
  else
    echo x86_64
  fi
}

Install_Zig() {
  if [ -e "${zig_install_dir}/zig" ]; then
    echo "${CWARNING}Zig already installed! ${CEND}"
    return
  fi

  zig_arch=$(Get_Zig_Arch)
  zig_tar=zig-${zig_arch}-linux-${zig_ver}.tar.xz
  zig_dir=zig-${zig_arch}-linux-${zig_ver}

  pushd ${oneinstack_dir}/src > /dev/null
  src_url=https://ziglang.org/download/${zig_ver}/${zig_tar} && Download_src
  tar xf ${zig_tar}
  rm -rf ${zig_install_dir}
  /bin/mv ${zig_dir} ${zig_install_dir}

  if [ -e "${zig_install_dir}/zig" ]; then
    cat > /etc/profile.d/zig.sh << EOF
export ZIG_HOME=${zig_install_dir}
export PATH=\${ZIG_HOME}:\$PATH
EOF
    . /etc/profile.d/zig.sh
    echo "${CSUCCESS}Zig ($(zig version)) installed successfully! ${CEND}"
    echo "${CMSG}Go CGO cross-compile example: CC=\"zig cc -target aarch64-linux-gnu\" GOOS=linux GOARCH=arm64 CGO_ENABLED=1 go build${CEND}"
    rm -f ${zig_tar}
  else
    echo "${CFAILURE}Zig install failed, Please contact the author! ${CEND}" && grep -Ew 'NAME|ID|ID_LIKE|VERSION_ID|PRETTY_NAME' /etc/os-release
    kill -9 $$; exit 1;
  fi
  popd > /dev/null
}

Uninstall_Zig() {
  if [ -e "${zig_install_dir}/zig" ] || [ -e /etc/profile.d/zig.sh ]; then
    rm -rf ${zig_install_dir} /etc/profile.d/zig.sh
    echo "${CMSG}Zig uninstall completed! ${CEND}"
  else
    echo "${CWARNING}Zig does not exist! ${CEND}"
  fi
}
