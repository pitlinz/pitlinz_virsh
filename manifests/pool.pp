/**
 * define a disk pool for virsh
 *
 * @todo restart pool if params changes
 *
 */
define pitlinz_virsh::pool(
    $ensure		= present,
    $type 		= "logical",
	$sources	= [],
	$targets	= ["<path>/dev/${name}</path>"],
	$autostart	= true,
) {

# --------------------------------------
# includes
# --------------------------------------

	include ::pitlinz_virsh

# --------------------------------------
# validation
# --------------------------------------

	validate_bool ($autostart)
	validate_re ($ensure, '^(present|defined|enabled|running|undefined|absent)$','Ensure must be one of defined (present), enabled (running), or undefined (absent).')

# --------------------------------------
# checks
# --------------------------------------

	if !defined(File["${::pitlinz_virsh::path_setup}/pools"]) {
	    file {"${::pitlinz_virsh::path_setup}/pools":
	        ensure 	=> directory
		}
	}


# --------------------------------------
# init
# --------------------------------------

	$xml_file 		= "${::pitlinz_virsh::path_setup}/pools/${name}.xml"
	$ensure_file = $ensure? {
		/(present|defined|enabled|running)/ => 'present',
		/(undefined|absent)/                => 'absent',
		default								=> undef
	}


# --------------------------------------
# main
# --------------------------------------

	file {"${xml_file}":
	    ensure	=> $ensure_file,
	    content => template("pitlinz_virsh/pool/$type.xml.erb"),
		require => File["${::pitlinz_virsh::path_setup}/pools"],
	}

	case $ensure_file {
	    'present': {
	        exec{"create_pool_${name}":
	            command => "/usr/bin/virsh pool-define ${xml_file}",
				creates => "/etc/libvirt/storage/${name}.xml",
				require	=> File["${xml_file}"],
				notify	=> Exec["start_pool_${name}"]
			}

			if $autostart {
		        exec{"autostart_pool_${name}":
		            command => "/usr/bin/virsh pool-autostart ${name}",
					creates => "/etc/libvirt/storage/autostart/${name}.xml",
					require	=> Exec["create_pool_${name}"]
				}
			}

			exec{"start_pool_${name}":
				command 	=> "/usr/bin/virsh pool-start ${name}",
				refreshonly => true
			}
	    }
	}

	/*
	if $autostart {
	    $autoparam = "autostart"
	} else {
	    $autoparam = ""
	}

	case $ensure_file {
	    'present': {
			exec{"start_pool_${name}":
			    command => "/usr/local/bin/virsh-pool.sh start ${xml_file} ${autoparam}",
				require => File["${xml_file}","/usr/local/bin/virsh-pool.sh"],
				unless	=> "/usr/local/bin/virsh-pool.sh status ${name}",
			}
		}

		'absent': {
			exec{"stop_pool_${name}":
			    command => "/usr/local/bin/virsh-pool.sh stop ${xml_file}",
			    require => File["${xml_file}","/usr/local/bin/virsh-pool.sh"],
				unless	=> "/usr/local/bin/virsh-pool.sh status ${name} isstopped",
			}
		}
	}
	*/
}
