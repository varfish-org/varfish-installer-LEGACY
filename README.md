# VarFish Installer Helper Files

This repository contains helper files for creating a VarFish installer instance.
Details on how to use this can be found in the [VarFish Manual: Installation](https://varfish-server.readthedocs.io/en/latest/installation.html) (work in progress).

This manual assumes that:

- All commands from below are run on your workstation `host` that runs the latest version of Red Hat/CentOS/Debian/Ubuntu.
- You have a (potentially virtual) machine setup that you can connect to via `ssh root@<varfish_host>` without having to type a password (SSH key setup).
  See the manual for exact requirements.

## Prerequisites

- Install Ansible ([Ansible Manual](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)).
- Install pwgen (`apt install pwgen` or `yum install pwgen`).

## Quickstart

### Clone the Installer

```bash
host:~$ git clone https://github.com/bihealth/varfish-installer.git
host:~$ cd varfish-installer
host:varfish-installer$
```

Consider making a fork of the repository to keep your configuration changes in Git.
Note that our `.gitignore` prevents adding the configuration files to Git, so you might want to update this in your fork.

### Install Ansible Roles via Ansible-Galaxy

```bash
host:varfish-installer$ make deps
```

### Generate Secret

The following will create the file `inventory/production/group_vars/all/secrets.yml` with a number of secret strings.
We would actually recommend using [Password Store](https://www.passwordstore.org/) and the [passwordstore Ansible integration](https://docs.ansible.com/ansible/latest/collections/community/general/passwordstore_lookup.html#ansible-collections-community-general-passwordstore-lookup).
However, the setup with GPG and `gpg-agent` is a bit tricky, so we will just store the password in plain text here.
Clearly, this is not suitable for a production setting.

```bash
host:varfish-installer$ make secrets
```

NB: the installer will later setup a user `root` in the VarFish app.
You can find its password with:

```bash
host:varfish-installer$ grep sodar_core_app_superuser_password \
    inventories/production/group_vars/all/secrets.yml
sodar_core_app_superuser_password: "Uethah3hoowu0duroo0shoh4thiekai2enai6she"
```

### Configure Installer

Copy the configuration `.yml.EXAMPLE` files to `.yml` files.

```bash
host:varfish-installer$ make configs
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
host:varfish-installer$ make jannovar
```

Second, install the PostgreSQL server that VarFish will use for its backend.

```bash
host:varfish-installer$ make postgres
```

Finally, install the VarFish server and initialize the database.

```bash
host:varfish-installer$ make varfish
```

At this point, you already have a working Varfish installation yet without any background data, you can refer to it at `https://<varfish_host>/`.

### Download & Import Background Data

The next step is to download the background data including the gnomAD database etc.
First, download and extract the data. The data releases can be found here:

https://file-public.bihealth.org/transient/varfish/

```bash
host:~$ ssh root@<varfish_host>
root@varfish:~$ mkdir -p /srv/varfish-data-release-<VERSION>
root@varfish:~$ cd /srv/varfish-data-release-<VERSION>
root@varfish:~$ wget https://file-public.bihealth.org/transient/varfish/varfish-server-background-db-<VERSION>.tar.gz
root@varfish:~$ tar xf varfish-server-background-db-<VERSION>.tar.gz
```

Then, import:

```bash
root@varfish:~$ su - varfish
varfish@varfish:~$ varfish-manage import_tables --tables-path /srv/varfish-data-release-<VERSION>/
```

The last step will take a long time, depending on the I/O performance of your server.
For reference, on a non-VM server using fast SSD-based RAID storage, this takes ~12h.

After the successful completion of the last step, you will have a working

### Creating Users

Log in to your VarFish instance with user `root` and the password that was generated (in this example `Uethah3hoowu0duroo0shoh4thiekai2enai6she`, but this will differ in your installation):

![VarFish Login](.figures/varfish_login.png)

On the top right corner of the VarFish site you will find a menu. Select the `Django Admin` subentry.

![VarFish Menu](.figures/varfish_menu.png)

A new tab will open with the Django admin settings. Scroll down to find the `Users` section, click `add` to a new user and follow the instructions on screen.

![VarFish Django Admin](.figures/varfish_django_admin.png)


## Proper SSL Certificates

By default, VarFish will generate a self-signed certificate.
You can also provide a custom certificate filling `inventories/produciton/group_vars/all/ssl.yml` with your certificate and unencrypted secret key.
Again, we recommend to use a password store setup and show how to use unencrypted values for demonstration purposes only.

```
- name: varfish
  cert: |
    -----BEGIN CERTIFICATE-----
    MIIE5zCCAs+gAwIBAgIUJ+byPgg2I3WXgPM7rtC/gVVI35YwDQYJKoZIhvcNAQEL
    BQAwEjEQMA4GA1UEAwwHdmFyZmlzaDAeFw0yMDEwMDYxMzE5MzJaFw0zMDEwMDQx
    [...]
    -----END CERTIFICATE-----
  key: |
    -----BEGIN RSA PRIVATE KEY-----
    MIIJKQIBAAKCAgEA+9Ax9v6iBXLXPdxvcmBaqhE4kMmmEW+Z70r3LQx+s/9T9O1c
    5NLU1DiDKgBnqg84DvEhjlEQNbfJQeZSg0gf5CEeFzjzAMbngckD7s/8bwOwYDhl
    [...]
    -----END RSA PRIVATE KEY-----
```
