define pitlinz_virsh::qemu::guest::disk::qcow2(
    $src		= undef,
    $size 		= '20G',
    $options	= "",
    $ensure		= present
) {

    if $src == undef {
        fail("no src")
    }

	$imgDir = dirname($src)

	if !defined(Exec["mkdir_${imgDir}"]) {
	    exec {"mkdir_${imgDir}":
	        command => "/bin/mkdir -p ${imgDir}",
			creates => $imgDir
		}
	}

    if !defined(File["$imgDir"]) {
      file {"$imgDir":
        ensure 	=> directory,
        owner	=> "${::pitlinz_virsh::user}",
        group	=> "${::pitlinz_virsh::group}",
        require => Exec["mkdir_${imgDir}"]
      }
    }


    if $options != "" {
        $_options = "-o ${options}"
    } else {
        $_options = ""
    }

    $str_cmd = "/usr/bin/qemu-img create -f qcow2 ${_options} ${src} ${size}"

	if $ensure == present {
    exec{"qcow_create_${src}":
      command	=> $str_cmd,
      creates => $src,
      require => File["$imgDir"]
		}
	}
}
