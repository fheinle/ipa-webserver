
# krb-webserver

This is a wrapper around `Apache` and `Apache::Vhost` from
[puppetlabs/apache](https://forge.puppet.com/puppetlabs/apache) that adds SSL
and Kerberos compatible with [FreeIPA](https://www.freeipa.org).

#### Table of Contents

1. [Description](#description)
2. [Setup](#setup)
    * [What krb-webserver affects](#what-krb-webserver-affects)
    * [Setup requirements](#setup-requirements)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)

## Description

This wrapper installs the required Apache2 modules for authentication using
Kerberos and SSSD, so it also respects HBAC rules defined in FreeIPA.

For a vhost, it enables Kerberos based authentication for its document root
and sets up its configuration with an SSL certificate retrieved from your FreeIPA
server. Both options can be disabled.

## Setup

### What krb-webserver affects

* Apache configuration: enables modules
* Apache vhosts: adds 1 http and optionally 1 https vhost
* PAM configuration: adds new config file in `/etc/pam.d/`
* File system: creates document root directory

### Setup Requirements

You should set up a Kerberos principal in FreeIPA and retrieve both an SSL key
and accompanying certificate for your host. Also, retrieve the ticket for your
principal and store it in a keytab accessible by apache, e.g. in
`/etc/apache2/krb5_keytab`.

You will need to install and set up apache separately, maybe with
[puppetlabs/apache](https://forge.puppet.com/puppetlabs/apache).

## Usage

Configuring your webserver for Kerberos auth is easy:

```puppet
class {'::webserver': }
```

This will install required packages and enable `mod_authnz_pam` and
`mod_auth_kerb`. Also, it will create a new pam configuration for web access
that requires *SSSD* for authorization.

Setting up a new vhost:

```puppet
webserver::vhost {'awesome_vhost':
    $vhost_name        = $::facts['fqdn'],
    $docroot           = "/var/www/${vhost_name}/html",
    $ssl               = true,
    $kerberos          = true,
    $web_user          = 'www-data',
    $default_vhost     = false,
    $ssl_cert_filename = "/etc/apache2/ssl/${vhost_name}.crt.crt",
    $ssl_key_filename  = "/etc/apache2/ssl/${vhost_name}.crt.key",
    $krb_auth_realm    = undef,
    $krb_5keytab       = undef,
    $krb_servicename   = 'http'
}
```

Those are the default settings, obviously you need to override them with your
customizations. Especially make sure to set the correct values to `$krb5_*`.

## Reference

### Class `webserver`

Enables `mod_auth_kerb` and `mod_authnz_pam`, create a PAM configuration file
that requires *SSSD*.

* This class has no configuration settings

### Defined Type `webserver::vhost`

Create a new apache virtual host. This will create a `$docroot` directory owned
by `$web_user`. If `$ssl` is set to true, additionally to a `https` vhost it
will create a `http` vhost redirecting to `https` automatically.

* `vhost_name`: Hostname the vhost uses, i.e. `ServerName` in apache
* `docroot`: directory static files will be served from
* `ssl`: *bool* use SSL?
* `kerberos`: *bool* require Kerberos?
* `web_user`: username `docroot` will belong to
* `default_vhost`: *bool* is this the default apache vhost?
* `ssl_cert_filename`: Path to SSL certificate
* `ssl_key_filename`: Path to SSL private key
* `krb_auth_realm`: *optional if* `kerberos` *is* `false` name of your kerberos
  realm
* `krb_5keytab`: *optinal if* `kerberos` *is* `false` path to kerberos keytab
  file accessible by apache
* `krb_servicename` *optional if* `kerberos` *is* `false` name of your kerberos
  service name you set up in FreeIPA


## Limitations

Currently this is a limited wrapper around vhost creation, i.e. it will not pass
through additional apache vhost settings to the module it wraps. You may,
however, access that instance of `Apache::Vhost` using the regular puppet syntax
of `Apache::Vhost[your.vhost.here]`.