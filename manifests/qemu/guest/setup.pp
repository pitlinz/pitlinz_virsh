# create a setup script for the node
#

define pitlinz_virsh::qemu::guest::setup (
    $ostype		= 'linux',
    $installurl	= "http://archive.ubuntu.com/ubuntu/dists/bionic/main/installer-amd64/",
    $isoimage	= '',
    $boot		= '',

    $nodeid     = undef,
    $memory		= 4096,
    $cpus		= 1,

) {

    $_baseParams = "--os-type ${ostype} -n ${name} -r ${memory} --vcpus=${cpus}"

    if $nodeid < 10 {
    	$_grafics = "--graphics vnc,port=590${nodeid},keymap=de "
	} else {
	    $_grafics = "--graphics vnc,port=59${nodeid},keymap=de "
	}

    if "${boot}" == 'hd' {
        $_install = ''
	    $_boot	  = '--boot hd'
    } elsif "${isoimage}" != "" {
		$_install = "--cdrom ${isoimage}"
		$_boot	  = '--boot cdrom'
	} elsif "${installurl}" != "" {
		$_install = "-l ${installurl}"
		$_boot 	  = ''
    } else {
        $_install = ''
	    $_boot	  = $boot
    }

    ::concat{"${::pitlinz_virsh::path_setup}/${name}.sh":
		mode	=> '550'
	}

    ::concat::fragment{"${::pitlinz_virsh::path_setup}/${name}_head":
	    target	=> "${::pitlinz_virsh::path_setup}/${name}.sh",
		content	=> template("pitlinz_virsh/qemu/virtinst-00-head.erb"),
		order   => "00",
	}

    concat::fragment{"${::pitlinz_virsh::path_setup}/${name}_cmd":
	    target	=> "${::pitlinz_virsh::path_setup}/${name}.sh",
		content	=> "\n/usr/bin/virt-install ${_baseParams} \$DISK \$NETWORK ${_grafics} ${_install} ${_boot} --wait 0\n\n",
		order   => "99",
	}

}
