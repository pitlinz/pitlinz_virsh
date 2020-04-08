define pitlinz_virsh::nginx::conf_redirect (
	$servername 	= undef,
	$listenPort		= 80,
	$proto			= 'https',
	$host			= '$host'
) {

	$confFile = "/etc/nginx/sites-available/server_${servername}_${listenPort}.conf"

    concat::fragment{"${confFile}_redirect_${name}":
        target 	=> "${confFile}",
		content => template("pitlinz_virsh/nginx/redirect.conf.erb"),
		order	=> "300",
		require	=> Package["nginx"],
		notify	=> Service["nginx"]
	}

}
