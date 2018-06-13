/**
 * include ssl configuration
 *
 */
define  pitlinz_virsh::nginx::conf_ssl (
	$servername 			= undef,
	$listenPort				= 443,
  	$ssl_certificate 		= undef,
  	$ssl_key 				= undef,
) {

	$confFile = "/etc/nginx/sites-available/server_${servername}_${listenPort}.conf"

	concat::fragment{"${confFile}_ssl":
	    target	=> "${confFile}",
		content	=> template("pitlinz_virsh/nginx/ssl.conf.erb"),
		order   => "300",
		require	=> Package["nginx"],
		notify	=> Service["nginx"]
	}

}
