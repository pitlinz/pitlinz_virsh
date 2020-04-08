# creates the firewall hooks
#
# example hook calls
# ---------------------------------------
## virsh start $nodename
# $nodename prepare begin -
# $nodename start begin -
# $nodename started begin -
#---------------------------------------
## virsh shutdown $nodename
# $nodename stopped end -
# $nodename release end -
#---------------------------------------
## virsh destroy $nodename
# $nodename stopped end -
# $nodename release end -
#---------------------------------------
#
define pitlinz_virsh::qemu::guest::firewall(
    $ensure 	= present,
    $nodename	= undef,
    $nodeid	  	= 0,

    $netid		= $::pitlinz_virsh::hostid,

    $intip		= undef,
    $extip		= $::ipaddress,
    $extif		= $::libvirtextif,
    $extnetmask = '255.255.255.192',

	$tcpports 	= "",
	$udpports	= "",
	$icmpports	= "",

	$fwnat		= [],
	$fwfilter	= [],

) {

	if !defined(File["${::pitlinz_virsh::path_etc}/hooks/firewall"]) {
		file{"${::pitlinz_virsh::path_etc}/hooks/firewall":
			ensure 	=> directory,
			require	=> Package["libvirt-bin"]
		}
	}

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

    if is_ip_address($intip) {
        $_intip = $intip
    } else {
        $_intip = "${::pitlinz_virsh::networkpre}${$_netid}.${nodeid}"
    }

	if ($nodeid < 10) {
	    $_sshport = "220${nodeid}"
	} else {
	    $_sshport = "22${nodeid}"
	}

	#notify{"guest ${name} ${extip} ${_intip}":}

	$fwhook = "${::pitlinz_virsh::path_etc}/hooks/firewall/${nodename}"

    if !defined(Concat[$fwhook]) {
    	::concat{$fwhook:
    		ensure 	=> $ensure,
    		mode	=> '550',
    		require => File["${::pitlinz_virsh::path_etc}/hooks/firewall"]
    	}
    }

	::concat::fragment{"${fwhook}_head":
	    target	=> "${fwhook}",
		content	=> template("pitlinz_virsh/hooks/firewall/00_head.erb"),
		order   => "00",
	}

	::concat::fragment{"${fwhook}_initstart":
	    target	=> "${fwhook}",
		content	=> template("pitlinz_virsh/hooks/firewall/10_initstart.erb"),
		order   => "10",
	}

	::concat::fragment{"${fwhook}_start_natfilter":
	    target	=> "${fwhook}",
		content	=> template("pitlinz_virsh/hooks/firewall/20_start_natfilter.erb"),
		order   => "20",
	}

	::concat::fragment{"${fwhook}_finish_start":
	    target	=> "${fwhook}",
		content	=> "\n\t\t;;\n",
		order   => "29",
	}

	::concat::fragment{"${fwhook}_initstop":
	    target	=> "${fwhook}",
		content	=> template("pitlinz_virsh/hooks/firewall/50_initstop.erb"),
		order   => "50",
	}


	::concat::fragment{"${fwhook}_finish_stop":
	    target	=> "${fwhook}",
		content	=> "\n\t\t;;\n",
		order   => "69",
	}


	::concat::fragment{"${fwhook}_footer":
	    target	=> "${fwhook}",
		content	=> template("pitlinz_virsh/hooks/firewall/99_footer.erb"),
		order   => "99",
	}

}
