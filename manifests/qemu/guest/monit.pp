/**
 * monit check for guest
 */
define pitlinz_virsh::qemu::guest::monit(
    $ensure 		= defined,
    $nodeid			= undef,
    $proc_checks	= [],

    $intip			= undef,
	$host_checks	= [],

) {
    include monit

    case $ensure {
        running: {
            $conf_ensure = present
            $proc_ensure = present
        }

        present: {
            $conf_ensure = present
            $proc_ensure = absent
        }

        default: {
            $conf_ensure = absent
            $proc_ensure = absent
        }
    }

#	notify{"${name}_conf_ensure: ${conf_ensure}":}


    monit::check::file{"virsh_${name}.xml":
        ensure	 => $conf_ensure,
        filepath => "/etc/libvirt/qemu/${name}.xml",
		mgroups	 => ['virsh',"virsh_${name}"]
	}



    if is_array($customlines) {
		$_proc_checks = concat([
      		"if failed host 127.0.0.1 port 59${nodeid} type tcp then alert",
		],$proc_checks)
    } else {
		$_proc_checks = [
      		"if failed host 127.0.0.1 port 59${nodeid} type tcp then alert",
		]
    }

    monit::check::process{"virsh_${name}":
        ensure			=> $proc_ensure,
        process 		=> "qemu-system-x86_64",
		pidfile			=> "/var/run/libvirt/qemu/${name}.pid",
		start			=> "/usr/bin/virsh start ${name}",
		stop			=> "/usr/bin/virsh shutdown ${name}",
		depends_on		=> ['libvirtd'],
		customlines		=> $_proc_checks,
		mgroups			=> ["virsh","virsh_${name}"]
	}

    if $proc_ensure == present {
        monit::check::host{"vhost_${name}":
            ensure			=> $proc_ensure,
            chkaddress      => $intip,
    		start			=> "/usr/bin/virsh start ${name}",
    		stop			=> "/usr/bin/virsh shutdown ${name}",
    		depends_on		=> ["virsh_${name}"],
    		customlines		=> $_proc_checks,
    		mgroups			=> ["virsh","virsh_${name}"]
    	}

        exec {"monit_lo_${name}":
            command => "/sbin/iptables -A INPUT -i lo -j ACCEPT",
            unless  => "/sbin/iptables -L INPUT -nv | /bin/grep lo | /bin/grep ACCEPT"
        }

        exec {"monit_vnc_${name}":
            command => "/sbin/iptables -A INPUT -d 127.0.0.1 -p tcp --dport 59${nodeid} -j ACCEPT",
            unless  => "/sbin/iptables -L INPUT -nv | /bin/grep '127.0.0.1'  | /bin/grep 59${nodeid} | /bin/grep ACCEPT"
        }

    }


}
