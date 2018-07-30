/**
 * create a virsh qemu domain
 */
define pitlinz_virsh::guest(
    $type		= 'qemu',

    $ensure 	= present,
	$nodeid	  	= undef,
    $netname    = 'default',
	$nicmodel	= "virtio",
	$extip		= "",
	$tcpports 	= "",
	$fwnat		= [],
	$fwfilter	= [],
	$cpus		= "1",
	$memory		= "4096",
    $disks 		= undef,
    $isoimage	= "",
    $boot		= "",
    $proxynames = "",
	$runinstall	= true,
	$installurl	= "http://archive.ubuntu.com/ubuntu/dists/xenial/main/installer-amd64/",
	$autostart	= true,
	$monit		= undef,
) {

	case $type {
	    'qemu': {
	        include ::pitlinz_virsh::qemu

	        ::pitlinz_virsh::qemu::guest{"${name}":
    			ensure 		=> $ensure,
				nodeid		=> $nodeid,
                netname     => $netname,
				extip		=> $extip,
				tcpports 	=> $tcpports,
				fwnat		=> $fwnat,
				fwfilter	=> $fwfilter,
				cpus		=> $cpus,
				memory		=> $memory,
    			disks 		=> $disks,
    			isoimage	=> $isoimage,
    			boot		=> $boot,
    			require		=> File["${::pitlinz_virsh::path_etc}/hooks/qemu"],
    			proxynames	=> $proxynames,
    			runinstall	=> $runinstall,
    			installurl	=> $installurl,
    			monit		=> $monit,
			}
	    }
	}

	if $autostart {
	    exec{"virsh_autostart ${name}":
			command => "/usr/bin/virsh autostart ${name}",
			creates	=> "${::pitlinz_virsh::path_etc}/${type}/autostart/${name}.xml"
		}
	} else {
	    file{"${::pitlinz_virsh::path_etc}/${type}/autostart/${name}.xml":
	        ensure => absent,
	        notify => Exec["virsh_autostart_disable ${name}"]
		}

	    exec{"virsh_autostart_disable ${name}":
			command => "/usr/bin/virsh autostart ${name} --disable",
			refreshonly => true
		}
	}

}
