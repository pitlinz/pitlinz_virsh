define pitlinz_virsh::nginx::conf_proxy (
    $servername		= undef,
    $listenPort		= "80",
	$path			= "/",
	$upname			= undef,
    $uppath         = '/',
	$timeout		= 30,
	$psettings		= [],
    $order          = 200,
) {
    $confFile = "/etc/nginx/sites-available/server_${servername}_${listenPort}.conf"

	if !defined(Concat["${confFile}"]) {
		concat{"${confFile}":
	    	ensure 	=> $ensure,
		    require	=> Package["nginx"],
		    notify	=> Service["nginx"],
		}
	}

	if $upname == undef {
	    $_upname=$name
	} else {
	    $_upname=$upname
	}

    concat::fragment{"${confFile}_proxy_${name}":
        target 	=> "${confFile}",
		content => template("pitlinz_virsh/nginx/proxylocation.erb"),
		order	=> $order,
	}
}
