/**
 * class to install virtualisation with virsh
 *
 *
 */
class pitlinz_virsh(
  $ensure		 = running,
  $hostid		 = -1,

  $extif		 = 'eth0',

  $bridgename  = 'virbr0',
  $netname	 = 'default',
  $networkpre	 = '192.168.',
  $localdomain = 'localnet',

  $servicename = 'libvirt-bin',

  $user		 = 'libvirt-qemu',
  $group		 = 'kvm',
  $dnsmasquser = 'libvirt-dnsmasq',

  $pidfile     = '/var/run/libvirtd.pid',
  $monit 	= {
      start		=> true,
		daemonchks	=> [
            "if cpu usage > 100% for 5 cycles then alert",
            "if cpu usage > 500% for 5 cycles then restart",
			"if mem > 54 MB for 5 cycles then alert",
		]
	},
) {
  if ($hostid < 0) or ($hostid > 254) {
    fail("wrong hostid")
  }

	if $hostid < 10 {
    $hostnetworkpre = "${networkpre}0${hostid}."
	} else {
		$hostnetworkpre = "${networkpre}${hostid}."
	}

  $path_base	= "/srv/virsh"
  $path_setup = "/srv/virsh/setup"
  $path_img	= "/srv/virsh/images"
  $path_cdrom	= "/srv/virsh/iso"
  $path_etc	= "/etc/libvirt"

	File{
    owner   => $user,
    group   => $group,
    mode    => '0555'
	}

  case $ensure {
		absent: {
	    $_pkg_ensure 	= purged
	    $_path_ensure 	= absent
	    $_file_ensure	= absent
    }

		default: {
	    $_pkg_ensure 	= latest
	    $_path_ensure 	= directory
	    $file_ensure	= present
    }
  }

	::pitlinz_common::package{['libvirt-bin', 'python-vm-builder','ruby-libvirt','bridge-utils','virtinst','virt-viewer','virt-top','libguestfs-tools']:
	    ensure => $_pkg_ensure
	}

    if $::lsbdistid == 'Ubuntu' {
        if (0.0 + $::operatingsystemrelease) < 16.04 {
            package{'ubuntu-virt-server':
                ensure => $_pkg_ensure
            }
        }

        if (0.0 + $::operatingsystemrelease) < 18.04 {
            $initscript = '/etc/init.d/libvirt-bin'
        } else {
            $initscript = '/etc/init.d/libvirtd'
        }
    } else {
        $initscript = '/etc/init.d/libvirt-bin'
    }

	if ($_path_ensure == directory) {
	    exec {"mkdir_${path_base}":
	    	command => "/bin/mkdir -p ${path_base}",
			creates => $path_base
		}

		file{[$path_setup,$path_img,$path_cdrom]:
		    ensure => directory,
		    require => Exec["mkdir_${path_base}"]
		}
	}


	file{"${path_etc}/hooks/daemon":
	    ensure	=> $_file_ensure,
	    content => template("pitlinz_virsh/hooks/daemon.erb"),
	    require	=> Package['libvirt-bin']
	}

	service{"${servicename}":
	    ensure => $ensure
	}

	file {"/usr/local/sbin/dnsmasqctl":
	    content => template("pitlinz_virsh/scripts/dnsmasq.erb"),
	    mode	=> "0550"
	}

	exec{"dnsmasqctlreload":
	    command => "/usr/local/sbin/dnsmasqctl reload",
		require	=> File["/usr/local/sbin/dnsmasqctl"],
		refreshonly => true
	}

	if is_hash($monit) {
	    include monit

		::monit::check::process{'libvirtd':
	    	pidfile		=> $pidfile,
	    	start		=> "${initscript} start",
			stop		=> "${initscript} stop",
			customlines => $monit[daemonchks],
			mgroups		=> ['virsh']
    	}


    	monit::check::programm {'virshdaemon_status':
			ensure      	=> $_file_ensure,
			scriptpath  	=> "${::pitlinz_virsh::path_etc}/hooks/daemon",
			scriptparams	=> 'status',
			depends_on  	=> ['libvirtd'],
			customlines 	=> [
				'if status != 0 then alert'
			],
			mgroups			=> ['virsh','firewall'],
			require         => File["${path_etc}/hooks/daemon"],
		}
	}
}
