# GitLab Docker Build Script

This Dockerfile will create a new Docker container running GitLab 6.4 on Ubuntu 12.04  It is forked from [crashsystems/gitlab-docker](crashsystems's version) that I couldn't get working

## Installation

Follow these instructions to download or build GitLab.

### Step 0: Install Docker

[Follow these instructions](http://www.docker.io/gettingstarted/#h_installation) to get Docker running on your server.

### Step 1: Pull Or Build GitLab

With Docker installed and running, do the following to obtain GitLab.

**Build It Yourself**

```shell
$ git clone https://github.com/wraithgar/gitlab-docker.git gitlab
$ cd gitlab-docker
$ docker build -t gitlab .
```

Note that since GitLab has a large number of dependencies, the build process will take a while.

### Step 2: Configure GitLab

Edit the following files in your cloned gitlab folder:

* **gitlab.yml**: Change the host field to match the hostname for your GitLab instance. Under *Advanced settings* in the config file, change the *ssh_port* setting for GitLab Shell to a port you want to forward from the Docker host to port 22 for this container, you will need that port number a little later so write it down. On a piece of paper. If you don't do this, you won't be able to commit changes through a git/SSH url. Also, make any additional changes, such as LDAP configs etc, at this time.
* **database.yml**: In the *production* section, set a good password for the gitlab MySQL password.
* **nginx**: Replace YOUR\_SERVER\_FQDN with the hostname for your GitLab instance. Replace PATH\_TO\_GITLAB\_DOCKER with the directory you checked the gitlab-docker repo into

In addition, set the mysqlRoot variable in firstrun.sh to a good password for your MySQL root user.

### Step 3: Create A New Container Instance

This build makes use of Docker's ability to map host directories to directories inside a container. It does this so that a user's custom configuration can be injected into the container at first start. In addition, since the data is stored outside the container, it allows a user to put the folder on faster storage such as an SSD for higher performance.

To create the container instance, run the following:

    cd /path/to/gitlab-docker

Remember that port number you wrote down? You're going to need it now.  In the example below I've used 1234 but it can be whatever.
Next, run this if you pulled the image from the Docker index:

    docker run -d -p 1234:22 -v /path/to/gitlab-docker:/srv/gitlab -name gitlab crashsystems/gitlab-docker

Or this if you built it yourself:

    docker run -p 1234:22 -d -v /path/to/gitlab-docker:/srv/gitlab -name gitlab gitlab

*/path/to/gitlab-docker* represents the folder created by the git clone on the Docker host, and will contain the GitLab instance's data. Make sure to move it to your desired location before running the container. Also, the first boot of the container will take a bit longer, as the firstrun.sh script will be invoked to perform various initialization tasks.

##### Default username and password
GitLab creates an admin account during setup. You can use it to log in:

    admin@local.host
    5iveL!fe

## Experimental: GitLab update via container rebuild

It should be possible to use updates to this build to update a GitLab server. The process is as follows:

1. Ether pull an updated version of this script from the Docker index, or git pull this repo and rebuild.
2. Stop your current instance, and remove it with docker rm.
3. Inside the gitlab-docker/ folder from the install steps, run *git checkout firstrun.sh* to restore the firstrun.sh script.
4. Edit the firstrun.sh and delete the section titled "Delete this section if restoring data from previous build." Replace this section with the code to run any necessary database migrations for the new version.
5. Rerun the process from step 3 of the installation instructions.

Note that while this process has been mostly tested, it has not yet been tested with DB migrations. As with any time you perform software updates, [do a backup](https://github.com/gitlabhq/gitlabhq/blob/master/doc/raketasks/backup_restore.md) first.
