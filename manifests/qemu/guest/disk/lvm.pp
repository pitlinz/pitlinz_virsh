define pitlinz_virsh::qemu::guest::disk::lvm(
    $vgname		= undef,
    $size 		= '20G',
    $ensure		= present
) {

	if $vgname == undef {
	    fail("no vgname")
	}

	if $ensure == present {
	    exec{"lvvolcreate_${name}":
	        command => "/usr/bin/virsh vol-create-as ${vgname} ${name} ${size}",
			creates => "/dev/${vgname}/${name}"
		}
	}

}
