define pitlinz_virsh::nginx::conf_vhost(
   	$listenIp 		= $::ipaddress,
   	$failoverIp		= undef,
   	$localIps		= undef,
	$listenPort		= 80,
	$nodename		= undef,
	$servername 	= undef,
	$serveraliases	= undef,
	$srvsettings	= [],

	$prio			= 100,
	$ensure			= present,

	$accesslog		= "",
	$errorlog		= "",
) {

    include pitlinz_virsh::nginx

    if $::pitlinz_virsh::hostid < 10 {
        $hostid = "0$::pitlinz_virsh::hostid"
    } else {
        $hostid = "$::pitlinz_virsh::hostid"
    }

    $confFile = "/etc/nginx/sites-available/server_${servername}_${listenPort}.conf"

	if !defined(Concat["${confFile}"]) {
		concat{"${confFile}":
	    	ensure 	=> $ensure,
		    require	=> Package["nginx"],
		    notify	=> Service["nginx"],
		}
	}

	if is_ip_address($failoverIp) {
	    $_failoverIp = $failoverIp
	} else {
	    $_failoverIp = ''
	}

	if is_array($serveraliases) {
	    $_seraliases = join($serveraliases," ")
	} else {
	    $_seraliases = ""
	}

	if is_array($localIps) {
	    $_localIps = $localIps
	} else {
	    if is_string($localIps) and $localIps != "" and $localIps != '-' {
	    	$_localIps = split($localIps,',')
	   	} else {
	   	    $_localIps = []
	   	}
	}

	if $accesslog == "" {
	    $_accesslog = "/var/log/nginx/${servername}-access.log"
	} else {
	    $_accesslog = $accesslog
	}

	if $errorlog == "" {
	    $_errorlog = "/var/log/nginx/${servername}-error.log"
	} else {
	    $_errorlog = $errorlog
	}

	concat::fragment{"${confFile}_serverinit":
	    target	=> "${confFile}",
		content	=> template("pitlinz_virsh/nginx/serverinit.erb"),
		order   => "100",
	}

	concat::fragment{"${confFile}_serverfooter":
	    target	=> "${confFile}",
		content	=> template("pitlinz_virsh/nginx/serverfooter.erb"),
		order   => "999",
	}

	if $ensure != absent {
	    $_ensure = link
	} else {
	    $_ensure = absent
	}


	file{"/etc/nginx/sites-enabled/1${prio}_vhost_${servername}_${listenPort}.conf":
		ensure => $_ensure,
		target => "${confFile}",
		notify => Service["nginx"]
	}

	$fwhook = "${::pitlinz_virsh::path_etc}/hooks/firewall/${nodename}"

	::concat::fragment{"${fwhook}_${servername}_${listenPort}":
	    target	=> "${fwhook}",
		content	=> "\n\t\t/sbin/iptables -A VIRSHINPUT -p tcp --dport ${listenPort} -d ${listenIp} -j ACCEPT -m comment --comment \"-VIRSH-${nodename}-FILTER-\"\n",
		order   => "21",
	}

	if is_ip_address($failoverIp) {
		::concat::fragment{"${fwhook}_${servername}_${listenPort}":
		    target	=> "${fwhook}",
			content	=> "\n\t\t/sbin/iptables -A VIRSHINPUT -p tcp --dport ${listenPort} -d ${failoverIp} -j ACCEPT -m comment --comment \"-VIRSH-${nodename}-FILTER-\"\n",
			order   => "21",
		}

	}

}
