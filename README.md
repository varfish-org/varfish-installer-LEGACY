# VarFish Installer Helper Files

This repository contains helper files for creating a VarFish installer instance.
Details on how to use this can be found in the [VarFish Manual: Installation](https://varfish-server.readthedocs.io/en/latest/installation.html) (work in progress).

This manual assumes that:

- All commands from below are run on your workstation `host` that runs a relatively modern version of Red Hat/CentOS, Debian/Ubuntu.
- You have the following (potentially virtual) machines setup and can connect via `ssh` to them as root without having to type a password (SSH key setup).
  See the manual for hardware requirements.
    - `varfish` for running VarFish
    - `postgres` for running the PostgreSQL server (can be run on the same machine as VarFish)

## Prerequisites

- Install Ansible.
- Install [Unix Password Store](https://www.passwordstore.org/)
- Setup GPG with gpg-agent.

## Quickstart

### Clone the Installer

Consider making a fork of this to keep your configuration changes.

```bash
host:~$ git clone git@github.com:bihealth/varfish-ansible.git
host:~$ cd varfish-ansible
host:varfish-ansible$
```

### Generate Passwords With Password-Store

First, define the environment variable `PASSWORD_STORE_DIR`.

```bash
host:varfish-ansible$ export PASSWORD_STORE_DIR=$PWD/.password-store
```

You will have to do so to setup your current shell session once before you call `ansible-playbook` through `make` below.

Then, initialize the password store (a working GPG and gpg-agent setup is required).

```bash
host:varfish-ansible$ pass init <gpgp ID; e.g., first.last@example.com>
```

Next, generate several passwords and keys:

```
host:varfish-ansible$ for name in \
        minio_access_key minio_secret_key password_postgres \
        password_root@sodar-core-app -n django_secret_key; do \
        pass generate varfish/$name 40; \
    done
```

With a proper gpg-agent setup, you will only have to enter your secret key passphrase once and it is then cached by the agent.

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

At this point, you already have a working Varfish installation, you can refer to it at `https://<varfish_host>/`.
