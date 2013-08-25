group { 'puppet': ensure => present }
Exec { path => [ '/bin/', '/sbin/', '/usr/bin/', '/usr/sbin/' ] }
File { owner => 0, group => 0, mode => 0644 }

class {'apt':
  always_apt_update => true,
}

Class['::apt::update'] -> Package <|
    title != 'python-software-properties'
and title != 'software-properties-common'
|>

    apt::key { '4F4EA0AAE5267A6C': }

apt::ppa { 'ppa:ondrej/php5':
  require => Apt::Key['4F4EA0AAE5267A6C']
}

class { 'puphpet::dotfiles': }

package { [
    'build-essential',
    'vim',
    'curl',
    'augeas-tools',
    'augeas-lenses',
    'libaugeas-ruby1.9.1',
  ]:
  ensure  => 'installed',
}

class { 'nginx': }


nginx::resource::vhost { 'welcome-to-php.dev':
  ensure       => present,
  server_name  => [
    'welcome-to-php.dev',
    'www.welcome-to-php.dev'
  ],
  listen_port  => 80,
  index_files  => [
    'index.html',
    'index.htm',
    'index.php'
  ],
  www_root     => '/vagrant/web',
  try_files    => ['$uri', '$uri/', '/index.php?$args'],
}

$path_translated = 'PATH_TRANSLATED $document_root$fastcgi_path_info'
$script_filename = 'SCRIPT_FILENAME $document_root$fastcgi_script_name'

nginx::resource::location { 'welcome-to-php.dev-php':
  ensure              => 'present',
  vhost               => 'welcome-to-php.dev',
  location            => '~ \.php$',
  proxy               => undef,
  try_files           => ['$uri', '$uri/', '/index.php?$args'],
  www_root            => '/vagrant/web',
  location_cfg_append => {
    'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
    'fastcgi_param'           => 'PATH_INFO $fastcgi_path_info',
    'fastcgi_param '          => $path_translated,
    'fastcgi_param  '         => $script_filename,
    'fastcgi_pass'            => 'unix:/var/run/php5-fpm.sock',
    'fastcgi_index'           => 'index.php',
    'include'                 => 'fastcgi_params'
  },
  notify              => Class['nginx::service'],
}

class { 'php':
  package             => 'php5-fpm',
  service             => 'php5-fpm',
  service_autorestart => false,
  config_file         => '/etc/php5/fpm/php.ini',
  module_prefix       => ''
}

php::module {
  [
    'php5-mysql',
    'php5-cli',
    'php5-curl',
    'php5-intl',
    'php5-mcrypt',
    'php-services-json',
  ]:
  service => 'php5-fpm',
}

service { 'php5-fpm':
  ensure     => running,
  enable     => true,
  hasrestart => true,
  hasstatus  => true,
  require    => Package['php5-fpm'],
}

class { 'php::devel':
  require => Class['php'],
}

class { 'php::pear':
  require => Class['php'],
}



$xhprofPath = '/var/www/xhprof'

php::pecl::module { 'xhprof':
  use_package     => false,
  preferred_state => 'beta',
}

if !defined(Package['git-core']) {
  package { 'git-core' : }
}

vcsrepo { $xhprofPath:
  ensure   => present,
  provider => git,
  source   => 'https://github.com/facebook/xhprof.git',
  require  => Package['git-core']
}

file { "${xhprofPath}/xhprof_html":
  ensure  => 'directory',
  owner   => 'vagrant',
  group   => 'vagrant',
  mode    => '0775',
  require => Vcsrepo[$xhprofPath]
}

composer::run { 'xhprof-composer-run':
  path    => $xhprofPath,
  require => [
    Class['composer'],
    File["${xhprofPath}/xhprof_html"]
  ]
}

nginx::resource::vhost { 'xhprof':
  ensure      => present,
  server_name => ['xhprof.welcome-to-php.dev'],
  listen_port => 80,
  index_files => ['index.php'],
  www_root    => "${xhprofPath}/xhprof_html",
  try_files   => ['$uri', '$uri/', '/index.php?$args'],
  require     => [
    Php::Pecl::Module['xhprof'],
    File["${xhprofPath}/xhprof_html"]
  ]
}


class { 'xdebug':
  service => 'nginx',
}

class { 'composer':
  require => Package['php5-fpm', 'curl'],
}

puphpet::ini { 'xdebug':
  value   => [
    '; priority=99',
    'xdebug.remote_autostart = 0',
    'xdebug.remote_connect_back = 1',
    'xdebug.remote_enable = 1',
    'xdebug.remote_handler = "dbgp"',
    'xdebug.remote_port = 9000'
  ],
  ini     => '/etc/php5/mods-available/xdebug-custom.ini',
  notify  => Service['php5-fpm'],
  require => Class['php'],
}

exec {"php5enmod xdebug-custom":
  require => Puphpet::Ini['xdebug'],
  creates => '/etc/php5/fpm/conf.d/99-xdebug-custom.ini',
  notify => Service['php5-fpm'],
}

puphpet::ini { 'php':
  value   => [
    '; priority=99',
    'date.timezone = "Europe/Berlin"'
  ],
  ini     => '/etc/php5/mods-available/php-custom.ini',
  notify  => Service['php5-fpm'],
  require => Class['php'],
}

exec {"php5enmod php-custom":
  require => Puphpet::Ini['php'],
  creates => '/etc/php5/fpm/conf.d/99-php-custom.ini',
  notify => Service['php5-fpm'],
}

puphpet::ini { 'custom':
  value   => [
    '; priority=99',
    'display_errors = On',
    'allow_url_fopen = 1',
    'allow_url_include = 0',
    'error_reporting = "E_ALL"'
  ],
  ini     => '/etc/php5/mods-available/custom.ini',
  notify  => Service['php5-fpm'],
  require => Class['php'],
}

exec {"php5enmod custom":
  require => Puphpet::Ini['custom'],
  creates => '/etc/php5/fpm/conf.d/99-custom.ini',
  notify => Service['php5-fpm'],
}

class { 'mysql::server':
  config_hash   => { 'root_password' => 'vagrant' }
}

mysql::db { 'welcome':
  grant    => [
    'ALL'
  ],
  user     => 'welcome',
  password => 'welcome',
  host     => 'localhost',
  charset  => 'utf8',
  require  => Class['mysql::server'],
}

class { 'phpmyadmin':
  require => [Class['mysql::server'], Class['mysql::config'], Class['php']],
}

nginx::resource::vhost { 'phpmyadmin':
  ensure      => present,
  server_name => ['phpmyadmin.welcome-to-php.dev'],
  listen_port => 80,
  index_files => ['index.php'],
  www_root    => '/usr/share/phpmyadmin',
  try_files   => ['$uri', '$uri/', '/index.php?$args'],
  require     => Class['phpmyadmin'],
}

nginx::resource::location { "phpmyadmin-php":
  ensure              => 'present',
  vhost               => 'phpmyadmin',
  location            => '~ \.php$',
  proxy               => undef,
  try_files           => ['$uri', '$uri/', '/index.php?$args'],
  www_root            => '/usr/share/phpmyadmin',
  location_cfg_append => {
    'fastcgi_split_path_info' => '^(.+\.php)(/.+)$',
    'fastcgi_param'           => 'PATH_INFO $fastcgi_path_info',
    'fastcgi_param '          => 'PATH_TRANSLATED $document_root$fastcgi_path_info',
    'fastcgi_param  '         => 'SCRIPT_FILENAME $document_root$fastcgi_script_name',
    'fastcgi_pass'            => 'unix:/var/run/php5-fpm.sock',
    'fastcgi_index'           => 'index.php',
    'include'                 => 'fastcgi_params'
  },
  notify              => Class['nginx::service'],
  require             => Nginx::Resource::Vhost['phpmyadmin'],
}

$fpm_cfg = '/etc/php5/fpm/pool.d/www.conf'

# # Commented out because I can't get it to work. replaced with the sed
# # command that follows.
# augeas { "php-fpm-user":
#   incl => $fpm_cfg,
#   changes => [
#     "set www/user vagrant",
#     "set www/group vagrant",
#   ],
#   lens => '@PHP',
#   require => Package['php5-fpm'],
# }

exec { "php5-fpm-user":
  command => "sed -i.bak -e 's/^\\s*user\\s*=\\s*www-data/user = vagrant/' -e 's/^\\s*group\\s*=\\s*www-data/group = vagrant/' ${fpm_cfg}",
  notify  => Service['php5-fpm'],
  require => Package['php5-fpm'],
}
