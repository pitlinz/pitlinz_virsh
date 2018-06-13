/**
 * define a nodes network
 */
define pitlinz_virsh::qemu::guest::network(
    $ensure 	= present,
    $nodename	= undef,
    $domain		= $::pitlinz_virsh::localdomain,
    $nodeid	  	= 0,

    $netid		= $::pitlinz_virsh::hostid,

    $netname	= "default",
	$model		= "virtio",
    $macaddr	= undef,
    $intip		= undef,
    $extip		= $::ipaddress,
    $extif		= $::libvirtextif,

	$tcpports 	= "",
	$udpports	= "",
	$icmpports	= "",

	$fwnat		= [],
	$fwfilter	= [],

	$instscript = true,

) {

    if $nodename == undef {
        fail('no name defined')
    }

    if !is_integer($nodeid) or $nodeid < 1 {
        fail('no id')
    }

    if $netid < 10 {
        $_netid = "0${netid}"
    } else {
        $_netid = "${netid}"
    }

    if $macaddr == undef {
        if($nodeid < 10) {
        	$_macaddr = "02:01:0a:0e:${_netid}:0${$nodeid}"
        } else {
            $_macaddr = "02:01:0a:0e:${_netid}:${$nodeid}"
        }
    } else {
        $_macaddr = $macaddr
    }

	if ($instscript ) {
	    concat::fragment{"${nodename}_net_${name}":
	        target 	=> "${::pitlinz_virsh::path_setup}/${nodename}.sh",
	        content => "\n#network: ${name}\nNETWORK=\"\$NETWORK --network network=${netname},model=${model},mac=${_macaddr}\"\n",
	        order	=> 10
	    }
    }

    if is_ip_address($intip) {
        $_intip = $intip
    } else {
        $_intip = "${::pitlinz_virsh::networkpre}${$_netid}.${nodeid}"
    }

	exec { "add_mac${_macaddr}_to_net${netname}":
	    command => "/usr/bin/virsh net-update ${netname} add ip-dhcp-host \"<host mac='${_macaddr}' name='${nodename}.${domain}' ip='${_intip}' />\" --live --config",
		unless => "/bin/grep  '${_macaddr}' /etc/libvirt/qemu/networks/${netname}.xml"
	}

	host{"${nodename}.${domain}":
	    ip => $_intip,
	    host_aliases => "${nodename}",
	    ensure => $ensure,
	    notify => Exec["dnsmasqctlreload"]
	}

	::pitlinz_virsh::qemu::guest::firewall{"fw_${nodename}":
	    ensure		=> $ensure,
	    nodename	=> $nodename,

	    nodeid		=> $nodeid,
	    netid		=> $netid,

	    intip		=> $_intip,
	    extip		=> $extip,
	    extif		=> $extif,

		tcpports 	=> $tcpports,
		udpports	=> $udpports,
		icmpports	=> $icmpports,

		fwnat		=> $fwnat,
		fwfilter	=> $fwfilter,
	}

}
