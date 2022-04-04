# usernetes_install
Automates the preparation and installation of Usernetes.

Usernetes requires preparation of a linux environment for user control of the cpu and io.
Manual instructions can be found at https://github.com/rootless-containers/usernetes/blob/master/README.md#quick-start

Here we automate the process in two scripts, part1 and part2. The machine must be manually rebooted between the two scripts.

The second script tests for cpu and io control and stops if it is not present.

Make sure that port 8080 is open for egress and ingress (at least).

Currently, there is a problem with user delegation on Fedora 35, Fedora 33 and CentOS 8 (at least).

Clone with git pull https://github.com/anthonyhartin/usernetes_install.git
