#!/bin/bash
# Author:  yeho <lj2007331 AT gmail.com>
# BLOG:  https://linuxeye.com
#
# Notes: OneinStack for CentOS/RedHat 7+ Debian 9+ and Ubuntu 16+
#
# Project home page:
#       https://oneinstack.com
#       https://github.com/oneinstack/oneinstack

Get_Docker_Platform() {
  if [ "${Family}" == 'debian' ]; then
    echo debian
  elif [ "${Family}" == 'ubuntu' ]; then
    echo ubuntu
  else
    case "${Platform}" in
      rhel)
        echo rhel
        ;;
      fedora)
        echo fedora
        ;;
      amzn)
        echo amazonlinux
        ;;
      *)
        echo centos
        ;;
    esac
  fi
}

Install_Docker() {
  if [ "${Wsl}" == 'true' ]; then
    echo "${CWARNING}WSL environment may not fully support Docker, please install Docker Desktop manually. ${CEND}"
  fi

  docker_platform=$(Get_Docker_Platform)
  [ "${OUTIP_STATE}"x == "China"x ] && DOWN_ADDR_DOCKER=https://mirrors.aliyun.com/docker-ce || DOWN_ADDR_DOCKER=https://download.docker.com

  if [ "${Family}" == 'rhel' ]; then
    yum -y install yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo ${DOWN_ADDR_DOCKER}/linux/${docker_platform}/docker-ce.repo
    yum -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  elif [ "${Family}" == 'debian' ] || [ "${Family}" == 'ubuntu' ]; then
    apt-get -y update
    apt-get -y install ca-certificates curl gnupg
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL ${DOWN_ADDR_DOCKER}/linux/${docker_platform}/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] ${DOWN_ADDR_DOCKER}/linux/${docker_platform} ${VERSION_CODENAME} stable" > /etc/apt/sources.list.d/docker.list
    apt-get -y update
    apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi

  if command -v docker >/dev/null 2>&1; then
    mkdir -p /etc/docker ${docker_data_dir}
    if [ "${OUTIP_STATE}"x == "China"x ]; then
      cat > /etc/docker/daemon.json << EOF
{
  "data-root": "${docker_data_dir}",
  "registry-mirrors": ["https://mirror.ccs.tencentyun.com", "https://docker.mirrors.ustc.edu.cn"]
}
EOF
    else
      cat > /etc/docker/daemon.json << EOF
{
  "data-root": "${docker_data_dir}"
}
EOF
    fi
    systemctl enable docker
    systemctl restart docker
    echo "${CSUCCESS}Docker ($(docker --version)) installed successfully! ${CEND}"
    echo "${CMSG}Docker Compose: $(docker compose version 2>/dev/null || echo 'included in docker-compose-plugin')${CEND}"
  else
    echo "${CFAILURE}Docker install failed, Please contact the author! ${CEND}" && grep -Ew 'NAME|ID|ID_LIKE|VERSION_ID|PRETTY_NAME' /etc/os-release
    kill -9 $$; exit 1;
  fi
}

Uninstall_Docker() {
  if command -v docker >/dev/null 2>&1 || [ -e /etc/docker/daemon.json ] || [ -e /etc/apt/sources.list.d/docker.list ] || [ -e /etc/yum.repos.d/docker-ce.repo ]; then
    systemctl stop docker containerd 2>/dev/null
    systemctl disable docker 2>/dev/null
    if [ "${Family}" == 'rhel' ]; then
      yum -y remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
      rm -f /etc/yum.repos.d/docker-ce.repo
    elif [ "${Family}" == 'debian' ] || [ "${Family}" == 'ubuntu' ]; then
      apt-get -y purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null
      rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.asc
    fi
    rm -f /etc/docker/daemon.json
    echo "${CMSG}Docker uninstall completed! ${CEND}"
  fi
}
