# configure the porxy to use letsencrypt signed certs
#
define pitlinz_virsh::nginx::conf_letsencrypt(
    $servername = $name,
    $serveraliases = '',
    $listenPort	= 80,
) {
    include ::pitlinz_virsh::nginx::letsencrypt

    exec{"mkdir_${servername}.well-known":
        command => "/bin/mkdir -p /var/www/${servername}/.well-known",
        creates => "/var/www/${servername}/.well-known"
    }

    $confFile = "/etc/nginx/sites-available/server_${servername}_${listenPort}.conf"

    concat::fragment{"${confFile}_letsencrypt":
	    target	=> "${confFile}",
		content	=> template("pitlinz_virsh/nginx/letsencrypt.erb"),
		order   => "101",
	}

    exec{"certbot ${servername}":
        command => "/usr/bin/certbot certonly --webroot -w /var/www/${servername}/ -d ${servername} -d ${serveraliases}",
        creates => "/etc/letsencrypt/live/${servername}/fullchain.pem",
        require => [Exec["mkdir_${servername}.well-known"],Service['nginx']]
    }
}
