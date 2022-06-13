#!/bin/sh
#
# first script for usernetes install
#---------------------------------------------------
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
echo "Usernetes install requires two scripts to be run with an intervening reboot to refresh user cgroups"
echo "This is the first script. Run it as an ordinary user. Sudo access is required."; fi
#---------------------------------------------------
workdir=$PWD
workuser=$USER
vercheck=`echo \`uname -r | cut -c 1-4\` 4.18 | awk '{if ($1<$2) print "fail"}'`
portcheck=`sudo netstat -pna | grep 6443`                                  
# ---------------first check some prerequisites-----------------
if ! compgen -u | grep -q $workuser; then echo "stopping because the user $workuser does not exist"; exit; fi
if ! sudo -l | grep -q " ALL"; then echo "stopping because you don't have sudo access. This is required"; exit; fi
if ! grep -q cgroup2 /proc/filesystems; then echo "stopping because cgroups v2 does not exist. please install"; exit; fi
# [ ! -f /sys/fs/cgroup/cgroup.controllers ] && { echo "stopping because cgroups do not exist. please install"; exit; }
[ "$vercheck" = "fail" ] && { echo "stopping because your kernel version is less than 4.18. please upgrade"; exit; }
[ -z `whereis newuidmap | gawk '{print \$2}'` ] && { echo "stopping because there is no newuidmap. please install"; exit; }
[ -z `whereis newgidmap | gawk '{print \$2}'` ] && { echo "stopping because there is no newuidmap. please install"; exit; }
sudo dnf -y install dnf-plugins-core wget bzip2 fuse iptables-legacy conntrack-tools net-tools        # prerequisites for usernetes
if cat /etc/os-release | grep PRETTY_NAME | grep -qi Fedora; then \
sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo; fi        # docker repo
if cat /etc/os-release | grep PRETTY_NAME | grep -qi CentOS; then \
sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo; fi        # centos repo
sudo dnf -y install docker-ce docker-ce-cli containerd.io                                             # docker and kubernetes utilities
if ! grep -q docker /etc/group; then sudo groupadd docker;fi                                          #
sudo usermod -aG docker $workuser                                                                     # allow docker to be used by the non root user
sudo systemctl enable docker; sudo systemctl start docker                                             # make sure docker always starts up
sudo grubby --update-kernel=ALL --args="systemd.unified_cgroup_hierarchy=1"                           # enable cgroup v2 at boot time
sudo mkdir -p /etc/systemd/system/user@.service.d                                                     # we are going to allow the user to use all controllers
cat <<EOF > delegate.conf                                                                             # create config file
[Service]
Delegate=yes
EOF
sudo mv delegate.conf /etc/systemd/system/user@.service.d/                                            # deploy config file
sudo systemctl daemon-reload
echo "Now reboot the machine in order to refresh user cgroups"
