# VarFish Installer Helper Files

This repository contains helper files for creating a VarFish installer instance.
Details on how to use this can be found in the [VarFish Manual: Installation](https://varfish-server.readthedocs.io/en/latest/installation.html) (work in progress).

This manual assumes that:

- All commands from below are run on your workstation `host` that runs the latest version of Red Hat/CentOS/Debian/Ubuntu.
- You have a (potentially virtual) machine setup that you can connect to via `ssh root@<varfish_host>` without having to type a password (SSH key setup).
  See the manual for exact requirements.

## Prerequisites

- Install Ansible.
- Install [Unix Password Store](https://www.passwordstore.org/) and setup GPG with `gpg-agent` support.
  NB: see the remark at "Generate Passwords With Password-Store" on how to work around this requirement at the cost of some security.

## Quickstart

### Clone the Installer

```bash
host:~$ git clone https://github.com/bihealth/varfish-ansible.git
host:~$ cd varfish-ansible
host:varfish-ansible$
```

Consider making a fork of the repository to keep your configuration changes in Git.
Note that our `.gitignore` prevents adding the configuration files to Git, so you might want to update this in your fork.

### Generate Passwords With Password-Store

First, define the environment variable `PASSWORD_STORE_DIR`.

```bash
host:varfish-ansible$ export PASSWORD_STORE_DIR=$PWD/.password-store
```

You will have to do so to setup your current shell session once before you call `ansible-playbook` through `make` below.

Then, initialize the password store.

```bash
host:varfish-ansible$ pass init <gpg ID; e.g., first.last@example.com>
```

Next, generate several passwords and keys and store them in the password store.

```
host:varfish-ansible$ for name in \
        minio_access_key minio_secret_key password_postgres \
        password_root@sodar-core-app -n django_secret_key; do \
        pass generate varfish/$name 40; \
    done
```

With a proper gpg-agent setup, you will only have to enter your secret key passphrase once and it is then cached by the agent.

NB: You could also search for all occurences of `passwordstore` in the `inventories/` folder and place static values.
For example, replace `"{{ lookup('passwordstore', 'varfish/password_postgres') }}"` with `"my-postgres-password"`.
This simplifies things and removes the dependency on GPG and `gpg-agent` but leads to a less secure environment.

### Install Ansible Roles via Ansible-Galaxy

```bash
host:varfish-ansible$ make deps
```

### Configure Installer

Copy the configuration `.yml.EXAMPLE` files to `.yml` files.

```bash
host:varfish-ansible$ make configs
```

You can now adjust the files `inventories/production/group_vars/all/*.yml` as follows.
Generally, you should look at all lines that contain the word `TDOO`.

See the inline documentation on the settings that you can change.
To see the effect of the variables, perform a `grep -R <variable_name> .imported_roles` to find its usage in the Ansible roles.

#### `jannovar.yml`

- no changes required

#### `servers.yml`

You must adjust `varfish_host` to a host specification that can be resolved by the machine running Ansible and all virtual servers that you have setup.
IPs will work regardless of your DNS setup.
Also, you can adjust the `/etc/hosts` file configuration on the servers so they can resolve the names to IPs.

By default, the other servers such as Jannovar REST API and PostgreSQL will be installed on the same machine as VarFish.
You can change this with the other variables in this file.

#### `varfish.yml`

- no changes required

### Install VarFish Server

First, install the Jannovar REST API server and data files.

```bash
host:varfish-ansible$ make jannovar
```

Second, install the PostgreSQL server that VarFish will use for its backend.

```bash
host:varfish-ansible$ make postgres
```

Finally, install the VarFish server and initialize the database.

```bash
host:varfish-ansible$ make varfish
```

At this point, you already have a working Varfish installation yet without any background data, you can refer to it at `https://<varfish_host>/`.

### Download & Import Background Data

The next step is to download the background data including the gnomAD database etc.
First, download and extract the data:

TODO: we need more work below

```bash
host:~$ ssh root@<varfish_host>
root@varfish:~$ mkdir -p /srv/varfish-data-release-<VERSION>
root@varfish:~$ cd /srv/varfish-data-release-<VERSION>
root@varfish:~$ wget XXX
root@varfish:~$ tar xf XXX
```

Then, import:

```bash
root@varfish:~$ su - varfish
varfish@varfish:~$ varfish-manage XXX
```

The last step will take a long time, depending on the I/O performance of your server.
For reference, on a non-VM server using fast SSD-based RAID storage, this takes ~12h.

After the successful completion of the last step, you will have a working
