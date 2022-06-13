#!/bin/sh
#
# Second script for usernetes install
#---------------------------------------------------
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
echo "Usernetes install requires two scripts to be run with an intervening reboot to refresh user cgroups"
echo "This is the second script. Run it as an ordinary user. Sudo access is required."; fi
#---------------------------------------------------
workdir=$PWD
workuser=$USER
vercheck=`echo \`uname -r | cut -c 1-4\` 4.18 | awk '{if ($1<$2) print "fail"}'`
portcheck=`sudo netstat -pna | grep 6443`                                  
# ---------------first check some prerequisites-----------------
if ! cat /sys/fs/cgroup/user.slice/user-$(id -u).slice/user@$(id -u).service/cgroup.subtree_control | grep -q cpu | grep -q io
then echo "stopping because the user cgroups do not allow control of the cpu and io."; exit; fi                                          # check cgroups, should contain cpu and io
if ! compgen -u | grep -q $workuser; then echo "stopping because the user $workuser does not exist"; exit; fi
if ! sudo -l | grep -q " ALL"; then echo "stopping because you don't have sudo access. This is required"; exit; fi
[ ! -f /sys/fs/cgroup/cgroup.controllers ] && { echo "stopping because cgroups do not exist. please install"; exit; }
[ "$vercheck" = "fail" ] && { echo "stopping because your kernel version is less than 4.18. please upgrade"; exit; }
[ -z `whereis newuidmap | gawk '{print \$2}'` ] && { echo "stopping because there is no newuidmap. please install"; exit; }
[ -z `whereis newgidmap | gawk '{print \$2}'` ] && { echo "stopping because there is no newuidmap. please install"; exit; }
wget https://github.com/rootless-containers/usernetes/releases/download/v20211108.0/usernetes-x86_64.tbz                         # get the latest usernetes release
tar xjf usernetes-x86_64.tbz
rm usernetes-x86_64.tbz
sudo install -o root -g root -m 0755 usernetes/bin/kubectl /usr/local/bin/kubectl
cd usernetes
sed '/kubectl -n kube-system wait/ s/./#&/' install.sh > tmp.dat; mv tmp.dat install.sh; chmod +x install.sh
./install.sh --cri=containerd                                                                                                    # the usernetes install
#docker run -td --name usernetes-node -p 127.0.0.1:6443:6443 --privileged ghcr.io/rootless-containers/usernetes --cri=containerd
#docker cp usernetes-node:/home/user/.config/usernetes/master/admin-localhost.kubeconfig docker.kubeconfig
#export KUBECONFIG=./docker.kubeconfig
sudo loginctl enable-linger                            # start user services automatically on system startup
echo "add \"export KUBECONFIG=/home/fedora/.config/usernetes/master/admin-localhost.kubeconfig\" to your persistent environment variables."
echo "usernetes install completed. "

