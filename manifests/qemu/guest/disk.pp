/**
 * defines a disk
 */
define pitlinz_virsh::qemu::guest::disk(
    $ensure		= present,
    $nodename	= undef,
	$type		= 'none',
	$src		= undef,
	$size		= undef,
	$options	= undef,
	$cache		= 'writethrough',
	$vgname		= 'vg0'
) {

    if $nodename == undef {
        fail("no node name")
    }

	case $type {
	    'qcow2': {
	        ::pitlinz_virsh::qemu::guest::disk::qcow2 {"${nodename}_disk_${name}":
				ensure 	=> $ensure,
				src	   	=> $src,
				size   	=> $size,
				options	=> $options
	        }

	        ::concat::fragment{"${nodename}_disk_${name}":
	            target 	=> "${::pitlinz_virsh::path_setup}/${nodename}.sh",
	            content => "\n#qcow2: ${name}\nDISK=\"\$DISK --disk path=${src},format=qcow2,cache=${cache}\"\n",
	            order	=> 20
	        }
	    }
	    'lvm': {
	        ::pitlinz_virsh::qemu::guest::disk::lvm  {"${name}":
				ensure 	=> $ensure,
				size   	=> $size,
				vgname	=> $vgname
			}

	        concat::fragment{"${nodename}_disk_${name}":
	            target 	=> "${::pitlinz_virsh::path_setup}/${nodename}.sh",
	            content => "\n#lvm: ${name}\nDISK=\"\$DISK --disk vol=${vgname}/${name}\"\n",
	            order	=> 20
	        }
	    }
	    'vmdk': {
	        ::concat::fragment{"${nodename}_disk_${name}":
	            target 	=> "${::pitlinz_virsh::path_setup}/${nodename}.sh",
	            content => "\n#qcow2: ${name}\nDISK=\"\$DISK --disk path=${src},cache=${cache}\"\n",
	            order	=> 20
	        }
	    }
	}

}
