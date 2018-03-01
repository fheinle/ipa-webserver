# webserver
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include webserver
class webserver (
  $ssl_dir = '/etc/apache2/ssl',
) {

  class { 'apache':
    default_mods      => false,
    default_vhost     => false,
    default_ssl_vhost => false,
    mpm_module        => 'worker',
    purge_configs     => true,
  }

  class { 'apache::mod::auth_kerb': }
  class { 'apache::mod::authnz_pam': }

  file { 'ssl directory':
    ensure => 'directory',
    path   => $ssl_dir,
    owner  => 'root',
    group  => 'root',
    mode   => '0770',
  }

  file { 'pam_sssd_http':
    ensure  => present,
    path    => '/etc/pam.d/http',
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => @(END)
    auth    required pam_sss.so
    account required pam_sss.so
    | END
  }
  $all_vhosts = lookup('webserver::vhosts', Hash, 'hash')

  $all_vhosts.each |$vhost| {
    if $vhost['vhost_name'] == $::facts['fqdn'] {
      create_resources(webserver::vhost,
      {$::facts['fqdn'] => $vhost})
    }
  }
}
