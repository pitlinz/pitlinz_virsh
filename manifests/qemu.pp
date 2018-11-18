/**
 * libvirt qemu
 */
class pitlinz_virsh::qemu (
  $ensure			= present,
	$vnc_listen		= '0.0.0.0',
	$vnc_password	= undef,
) {
    include pitlinz_virsh

    if $ensure == present {
	    $_dirensure = directory
	} else {
	    $_dirensure = $ensure
	}

	pitlinz_common::package{['ipxe-qemu',  'qemu', 'qemu-kvm']:
        ensure => $::pitlinz_virsh::_pkg_ensure
	}

	file{"${::pitlinz_virsh::path_etc}/qemu.conf":
        ensure	=> $ensure,
        content => template("pitlinz_virsh/conf/qemu.conf.erb"),
        require => Package["libvirt-bin"],
        notify  => Service["${::pitlinz_virsh::servicename}"]
	}

    $guesthookpath = "${::pitlinz_virsh::path_etc}/hooks/qemunodes"

	file{$guesthookpath:
        ensure => $_dirensure
	}

	file{"${::pitlinz_virsh::path_etc}/hooks/qemu":
	    ensure	=> $ensure,
	    content => template("pitlinz_virsh/hooks/qemu.erb"),
		mode	=> "555"
	}

	include ::pitlinz_virsh::qemu::network

}
