# webserver
#
# A description of what this class does
#
# @summary A short summary of the purpose of this class
#
# @example
#   include webserver
class webserver {

  class { 'apache::mod::auth_kerb': }
  class { 'apache::mod::authnz_pam': }

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
}
