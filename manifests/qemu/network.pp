#
# configure the default network
#
class pitlinz_virsh::qemu::network (
    $ensure				= running,

	$netname			= 'virnet0',
    $netid				= $::pitlinz_virsh::hostid,
   	$mac    			= undef,

   	$forward_mode		= 'route',
   	$forward_dev		= $::libvirtextif,
	$forward_interfaces = [$::libvirtextif],

	$bridge 			= "virbr0",

	$ip_address			= undef,
	$ip_netmask			= undef,

	$dhcp_start			= undef,
	$dhcp_end			= undef,
	$dhcp_bootp_file	= undef,

	$autostart			= true,
	$monit				= true,
) {

# --------------------------------
# requirements
# --------------------------------

    include ::pitlinz_virsh

# --------------------------------
# declarations
# --------------------------------

    $xml_file = "${::pitlinz_virsh::path_setup}/qemu_net_${netname}.xml"

	$ensure_file = $ensure? {
		/(present|defined|enabled|running)/ => 'present',
		/(undefined|absent)/                => 'absent',
		default								=> undef
	}

	if $netid < 0 {
	    fail("no network id set")
	}

	if $mac == undef {
	    if ($netid < 10) 	{$_mac = "02:01:0a:0e:0${netid}:01"}
		elsif ($netid <100)	{$_mac = "02:01:0a:0e:${netid}:01"}
		else 				{fail("network id must not be larger then 99")}
	} else {
	    $_mac = $mac
	}

	# -------------------------- ip_start values

	if $ip_address == undef {
	    if ($netid < 10) {
	        $_net_ippre	= "${::pitlinz_virsh::networkpre}0${netid}"
	    } elsif ($netid < 100) {
	        $_net_ippre = "${::pitlinz_virsh::networkpre}${netid}"
		} else {
			fail("network id must not be larger then 99")
		}

        $_ip_address 	= "${_net_ippre}.1"
        $_net_address 	= "${_net_ippre}.0/24"

	} else {
	    $_ip_address	= $ip_address
	    $arr_ipaddr		= split("${ip_address}",".")
        $_net_ippre     = "${arr_ipaddr[0]}.${arr_ipaddr[1]}.${arr_ipaddr[2]}"
	    $_net_address 	= "${arr_ipaddr[0]}.${arr_ipaddr[1]}.${arr_ipaddr[2]}.0/24"
	}

    if $ip_netmask {
        $_ip_netmask = $ip_netmask
    } else {
        $_ip_netmask = ip_netmask($_net_address)
    }

    if $dhcp_start {
        $_dhcp_start = $dhcp_start
    } else {
        $_dhcp_start = "${_net_ippre}.10"
    }

    if $dhcp_end {
        $_dhcp_end = $dhcp_end
    } else {
        $_dhcp_end = "${_net_ippre}.99"
    }


    if $forward_dev and has_interface_with($forward_dev) {
        $_forward_dev = $forward_dev
    } else {
        if $::lsbdistid == 'Ubuntu' and  (0.0 + $::operatingsystemrelease) >= 18.04 {
            $_forward_dev = ''
        }
    }

# --------------------------------
# concat
# --------------------------------

	concat{"${xml_file}":
		ensure 	=> $ensure_file,
	}

	concat::fragment{"${xml_file}_head":
	    target	=> "${xml_file}",
		content	=> template("pitlinz_virsh/network/head.erb"),
		order   => "00",
	}

	concat::fragment{"${xml_file}_forward":
	    target	=> "${xml_file}",
		content	=> template("pitlinz_virsh/network/forward.erb"),
		order   => "10",
	}

	concat::fragment{"${xml_file}_bridge":
	    target	=> "${xml_file}",
		content	=> template("pitlinz_virsh/network/bridge.erb"),
		order   => "20",
	}

	concat::fragment{"${xml_file}_ip":
	    target	=> "${xml_file}",
		content	=> template("pitlinz_virsh/network/ip.erb"),
		order   => "30",
	}

	concat::fragment{"${xml_file}_close":
	    target	=> "${xml_file}",
	    content => "\n</network>\n",
	    order	=> "99"
	}

    $pidfile = $::pitlinz_virsh::pidfile

	if !defined(File["${::pitlinz_virsh::path_etc}/hooks/network"]) {
		file{"${::pitlinz_virsh::path_etc}/hooks/network":
		    content => template("pitlinz_virsh/hooks/network.erb"),
		    require	=> Package['libvirt-bin'],
		    mode	=> '0550'
		}
	}

	if !defined(File["${::pitlinz_virsh::path_etc}/hooks/net"]) {
        file{"${::pitlinz_virsh::path_etc}/hooks/net":
            ensure => directory,
            require	=> Package['libvirt-bin'],
            mode   => '0550'
        }
    }

    file{"${::pitlinz_virsh::path_etc}/hooks/net/${netname}.conf":
        content => template("pitlinz_virsh/hooks/net/config.erb"),
        require	=> File["${::pitlinz_virsh::path_etc}/hooks/net"],
        mode	=> '0550'
    }

    if $netname != 'default' {
        exec{'destroy_net_default':
            command => '/usr/bin/virsh net-destroy default',
            unless  => "/usr/bin/test `/usr/bin/virsh net-list | /bin/grep -c default` -eq 0"
        }

        exec{'undef_net_default':
            command => '/usr/bin/virsh net-undefine default',
            unless  => "/usr/bin/test `/usr/bin/virsh net-list --all | /bin/grep -c default` -eq 0"
        }
    }

    exec{"virsh_net-define_${netname}":
        command => "/usr/bin/virsh net-define ${xml_file}",
        creates => "${::pitlinz_virsh::path_etc}/qemu/networks/${netname}.xml"
    }

    if $autostart {
        exec{"virsh_net-autostart_${netname}":
            command => "/usr/bin/virsh net-autostart ${netname}",
            creates => "${::pitlinz_virsh::path_etc}/qemu/networks/autostart/${netname}.xml"
        }

        exec{"virsh_net-start_${netname}":
            command => "/usr/bin/virsh net-start ${netname}",
            unless  => "/usr/bin/test `/usr/bin/virsh net-list | /bin/grep -c ${netname}` -eq 1"
        }

    }


	if ($monit) {
    	::monit::check::network{"virshnet_${netname}":
    	    ensure		=> $ensure_file,
    	    interface	=> $bridge,
    	    address		=> "${_net_ippre}.1",
    	    depends_on	=> ['libvirtd'],
			mgroups		=> ['virsh'],
    	}

    	::monit::check::host{"virshbridge_${bridge}":
    	    ensure		=> $ensure_file,
    	    chkaddress	=> "${_net_ippre}.1",
    	    customlines	=> [
    	        'if failed port 53 type tcp then alert',
    	        'if failed port 53 type udp then alert',
    	    ],
    	    mgroups		=> ['virsh','firewall'],
    	    depends_on	=> ['libvirtd']
		}

		monit::check::programm {"virshnet_${netname}_status":
			ensure      	=> $ensure_file,
			scriptpath  	=> "${::pitlinz_virsh::path_etc}/hooks/network",
			scriptparams	=> "${netname} status",
			start			=> "${::pitlinz_virsh::path_etc}/hooks/network",
			start_extras	=> "${netname} monitstart",
			stop			=> "${::pitlinz_virsh::path_etc}/hooks/network",
			stop_extras	    => "${netname} stop",
			depends_on  	=> ["virshdaemon_status"],
			customlines 	=> [
				"if status != 0 then alert",
				"if status != 0 for 1 cycles then restart",
				"if status != 0 for 10 cycles then unmonitor"
			],
			mgroups			=> ['virsh','firewall'],
			require     	=> File["${::pitlinz_virsh::path_etc}/hooks/network"],
		}
	}
}
