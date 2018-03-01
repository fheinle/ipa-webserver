# webserver::vhost
#
# Create a new virtual host
#
# @summary This is a wrapper arround 'puppetlabs/apache' with krb and ssl from FreeIPA
#
# @example
#   webserver::vhost { 'namevar': }
define webserver::vhost (
    $vhost_name    = $facts['fqdn'],
    $docroot       = "/var/www/$vhost_name/html",
    $ssl           = true,
    $kerberos      = false,
    $web_user      = 'www-data',
    $default_vhost = false,
    $ssl_cert_filename = "/etc/apache2/ssl/${vhost_name}.crt.crt",
    $ssl_key_filename  = "/etc/apache2/ssl/${vhost_name}.crt.key"
    $krb_auth_realm    = undef,
    $krb_5keytab       = undef,
    $krb_servicename   = 'http'
  ) {

  exec { "Create document root ${docroot}":
    creates => $docroot,
    command => "/bin/mkdir -p ${docroot}",
    cwd     => '/var/www/'
  }  -> file { $docroot:
    ensure  => directory,
    owner   => $web_user,
    group   => $web_user,
    mode    => '0750',
  }

  apache::vhost { $vhost_name:
    servername    => $vhost_name,
    port          => '80',
    docroot       => $docroot,
    default_vhost => $default_vhost,
    access_log    => true,
  }

  if $kerberos == true {
    Apache::Vhost[$vhost_name] {
      auth_kerb              => 'true',
      krb_auth_realm         => $krb_auth_realm,
      krb_5keytab            => $krb_5keytab,
      krb_servicename        => $krb_servicename,
      krb_local_user_mapping => 'on'
    }
  }

  if $ssl == true {
    ipa::sslcert { "${krb_servicename}/${facts['fqdn']}":
      fname   => $ssl_cert_filename,
      domain  => $facts['fqdn'],
      service => $krb_servicename,
    }
    Apache::Vhost[$vhost_name] {
      port              => '443',
      ssl_protocol      => 'TLSv1.2',
      ssl_cert_filename => $ssl_cert_filename,
      ssl_key_filename  => $ssl_key_filename,
    }
    apache::vhost { "redirect_${vhost_name}":
      ensure          => present,
      servername      => $vhost_name,
      port            => '80',
      docroot         => $docroot,
      redirect_status => 'permanent',
      redirect_dest   => "https://${vhost_name}/",
    }
  }
}
