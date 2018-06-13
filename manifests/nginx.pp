/**
 * install a reverse ngnix proxy
 */
class pitlinz_virsh::nginx(
    $ensure = running
) {

	if !defined(Package["nginx"])  {
    	package{"nginx": ensure => latest}
	}

	if !defined(Service["nginx"]) {
	    service{"nginx":
	        ensure => $ensure,
	        require=> Package["nginx"]
		}
	}

	file{"/etc/nginx/sites-enabled/default":
	    ensure => absent
	}

	file{"/etc/nginx/ssl":
	    ensure 	=> directory,
	    require	=> Package["nginx"]
	}


}
