#!/bin/sh
# To see all options in koji -p command check "koji -p cbs image-build --help"
set -eu


usage()
{
  cat << EOF
usage: $(basename $0) <argument>
  where <argument> is one of:
    6   -- build Vagrant images for CentOS 6
    7   -- build Vagrant images for CentOS 7
    8   -- build Vagrant images for CentOS 8
    all -- build Vagrant images for both CentOS 6 and 7 and 8
EOF
  exit 1
}


build_vagrant_image_8()
{
  BOOT_REPO="http://mirror.centos.org/centos/8/BaseOS/x86_64/os/"
  INSTALL_REPO=" --repo http://mirror.centos.org/centos/8/AppStream/x86_64/os/ \
  --repo http://mirror.centos.org/centos/8/extras/x86_64/os/ \
  --repo http://mirror.centos.org/centos/8/PowerTools/x86_64/os/"
  build_vagrant_image 8
}

build_vagrant_image_67()
{
  EL_MAJOR=$1
  BOOT_REPO="http://mirror.centos.org/centos/${EL_MAJOR}/os/x86_64/"
  INSTALL_REPO=" --repo http://mirror.centos.org/centos/${EL_MAJOR}/extras/x86_64/ \
  --repo http://mirror.centos.org/centos/${EL_MAJOR}/updates/x86_64/ "
  build_vagrant_image $EL_MAJOR
}

build_vagrant_image()
{
  # The kickstart files are in the same directory as this script
  KS_DIR=$(dirname $0)

  # Always wait if stdout is not a tty (needed by ci.centos.org)
  if [ ! -t 1 ]; then WAIT="--wait"; fi

  EL_MAJOR=$1
  koji -p cbs image-build \
    centos-${EL_MAJOR} 1  cloudinstance${EL_MAJOR}-common-el${EL_MAJOR} \
    ${BOOT_REPO}  x86_64 \
    --release=1 \
    --distro RHEL-${EL_MAJOR}.0 \
    --ksver RHEL${EL_MAJOR} \
    --kickstart=${KS_DIR}/centos${EL_MAJOR}.ks \
    --format=vagrant-libvirt \
    --format=vagrant-virtualbox \
    --format=vagrant-vmware-fusion \
    --format=vagrant-hyperv \
    --factory-parameter fusion_scsi_controller_type pvscsi \
    --ova-option vagrant_sync_directory=/vagrant \
    ${INSTALL_REPO} \
    --scratch \
    ${WAIT:-"--nowait"} \
    --disk-size=40
}


if [ $# -ne 1 ]; then
  usage
fi

case $1 in
  6)
    build_vagrant_image_67 6
    ;;
  7)
    build_vagrant_image_67 7
    ;;
  8)
    build_vagrant_image_8
    ;;
  all)
    build_vagrant_image_67 6
    build_vagrant_image_67 7
    build_vagrant_image_8
    ;;
  *)
    usage
    ;;
esac

# vim: set sw=2:
