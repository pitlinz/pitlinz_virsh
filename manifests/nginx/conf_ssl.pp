/**
 * include ssl configuration
 *
 */
define  pitlinz_virsh::nginx::conf_ssl (
	$servername 			= undef,
	$listenPort				= 443,
	$target						= undef,
	$ssl_certificate 	= undef,
	$ssl_key 					= undef,
) {
	if $target != undef {
		$_confFile = $target
	} else {
		$_confFile = "/etc/nginx/sites-available/server_${servername}_${listenPort}.conf"
	}

	concat::fragment{"${_confFile}_ssl":
		target	=> "${_confFile}",
		content	=> template("pitlinz_virsh/nginx/ssl.conf.erb"),
		order   => "300",
		require	=> Package["nginx"],
		notify	=> Service["nginx"]
	}

}
