/**
 * define a qemu domain
 */
define pitlinz_virsh::qemu::guest(
    $ensure = present,
	$nodeid	  	= undef,
	$netid		= $::pitlinz_virsh::hostid,
	$extip		= $::ipaddress,
	$nicmodel	= "virtio",
	$tcpports 	= "",
	$fwnat		= [],
	$fwfilter	= [],
	$cpus		= "1",
	$memory		= "4096",
    $disks 		= undef,

    $ostype		= "linux",
    $installurl	= "http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/",
    $isoimage	= "",
    $boot		= "",

	$proxynames	= "",
	$proxyport	= "80",
	$runinstall	= true,
	$monit		= undef,
) {

    if !is_integer($nodeid) {
        fail("nodeid is not a number")
    }

    if $ip_address == undef {
        $arr_ipAddr = split("${::pitlinz_virsh::networkpre}",".")

		if $arr_ipAddr[2] != '' {
		   $_ip_address = "${::pitlinz_virsh::networkpre}${netid}.${nodeid}"
		} else {
		   	if ($netid < 10)		{$_ip_address = "${::pitlinz_virsh::networkpre}0${netid}.${nodeid}"}
			elsif ($netid < 100)	{$_ip_address = "${::pitlinz_virsh::networkpre}${netid}.${nodeid}"}
			else					{fail("network id (host id) must not be larger then 99")}
		}
	}

	::concat{"${::pitlinz_virsh::path_setup}/${name}.sh":
		ensure 	=> $ensure,
		mode	=> '550'
	}


	::concat::fragment{"${::pitlinz_virsh::path_setup}/${name}_head":
	    target	=> "${::pitlinz_virsh::path_setup}/${name}.sh",
		content	=> template("pitlinz_virsh/qemu/virtinst-00-head.erb"),
		order   => "00",
	}

	# notify{"qemu guest ${name} ${extip} ${nodeid}":}

    ::pitlinz_virsh::qemu::guest::network{"net_${name}":
        ensure 		=> $ensure,
        nodename	=> $name,
        nodeid		=> $nodeid,
        model		=> $nicmodel,
        extip		=> $extip,
		tcpports 	=> $tcpports,
		fwnat		=> $fwnat,
		fwfilter	=> $fwfilter,
    }

    if is_hash($disks) {
   		$disk_defaults = {
  			ensure   => $ensure,
  			nodename => $name,
  			type	 => 'none'
		}
		create_resources(::pitlinz_virsh::qemu::guest::disk, $disks, $disk_defaults)
    }

    $_baseParams = "--os-type ${ostype} -n ${name} -r ${memory} --vcpus=${cpus}"

    if $nodeid < 10 {
    	$_grafics = "--graphics vnc,port=590${nodeid},keymap=de "
	} else {
	    $_grafics = "--graphics vnc,port=59${nodeid},keymap=de "
	}

	if "${isoimage}" != "" {
		$_install = "--cdrom ${isoimage}"
		$_boot	  = "--boot cdrom"
	} elsif "${installurl}" != "" {
		$_install = "-l ${installurl}"
		$_boot 	  = $boot
	} else {
	    $_install = ""
	    $_boot	  = $boot
	}

	concat::fragment{"${::pitlinz_virsh::path_setup}/${name}_cmd":
	    target	=> "${::pitlinz_virsh::path_setup}/${name}.sh",
		content	=> "\n/usr/bin/virt-install ${_baseParams} \$DISK \$NETWORK ${_grafics} ${_install} ${_boot} --wait 0",
		order   => "99",
	}

	if $runinstall {
		exec{"setup_${name}":
		    command => "${::pitlinz_virsh::path_setup}/${name}.sh",
		    creates => "/etc/libvirt/qemu/${name}.xml",
		    require => Concat["${::pitlinz_virsh::path_setup}/${name}.sh","${::pitlinz_virsh::path_etc}/hooks/firewall/${name}"]
		}
	}

	if $proxynames != "" {
	    include ::pitlinz_virsh::nginx

		::pitlinz_virsh::nginx::conf_vhost{"${name}":
		   	nodename		=> $name,
		    listenIp		=> $extip,
		    localIps		=> $ip_address,
		    servername		=> "${name}.${::pitlinz_virsh::localdomain}",
		    serveraliases	=> $proxynames,
		}

		::pitlinz_virsh::nginx::conf_upstream{"${name}":
			    path		=> "/",
				nodeips		=> [ "${_ip_address}" ],
				notify		=> Service["nginx"],
				require		=> Package["nginx"]
		}

		::pitlinz_virsh::nginx::conf_proxy{"${name}":
		    servername	=> "${name}.${::pitlinz_virsh::localdomain}",
		    upname		=> "${name}",
		}
	}

	if is_hash($monit) {
		pitlinz_virsh::qemu::guest::monit{"${name}":
		    ensure 	=> $monit[ensure],
		    nodeid	=> $nodeid
		}
	} else {
		pitlinz_virsh::qemu::guest::monit{"${name}":
		    ensure	=> absent
		}
	}

}
