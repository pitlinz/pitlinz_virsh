# virsh qemu hook
#
define pitlinz_virsh::qemu::guest::hook (
  $ensure   => present,

) {

  $hookfile = "${pitlinz_virsh::qemu::guesthookpath}/${name}.sh"
  $caseend  = "   ;;\n"

  if !defined(Concat[$hookfile]) {
    ::concat{$fwhook:
      ensure 	=> $ensure,
      mode	=> '550',
    }
  }

  ::concat::fragment{"${hookfile}_head":
    target	=> $hookfile,
		content	=> template("pitlinz_virsh/hooks/qemu/00_head.erb"),
		order   => "00",
	}

  ::concat::fragment{"${hookfile}_prepare":
    target	=> $hookfile,
		content	=> template("pitlinz_virsh/hooks/qemu/10_prepare.erb"),
		order   => "10",
	}

  ::concat::fragment{"${hookfile}_prepare_end":
    target	=> $hookfile,
		content	=> $caseend,
		order   => "19",
	}

  ::concat::fragment{"${hookfile}_start":
    target	=> $hookfile,
		content	=> template("pitlinz_virsh/hooks/qemu/20_start.erb"),
		order   => "20",
	}

  ::concat::fragment{"${hookfile}_start_end":
    target	=> $hookfile,
		content	=> $caseend,
		order   => "29",
	}

  ::concat::fragment{"${hookfile}_started":
    target	=> $hookfile,
		content	=> template("pitlinz_virsh/hooks/qemu/30_started.erb"),
		order   => "30",
	}

  ::concat::fragment{"${hookfile}_startend_end":
    target	=> $hookfile,
		content	=> $caseend
		order   => "39",
	}

  ::concat::fragment{"${hookfile}_stopped":
    target	=> $hookfile,
		content	=> template("pitlinz_virsh/hooks/qemu/70_stopped.erb"),
		order   => "70",
	}

  ::concat::fragment{"${hookfile}_stopped_end":
    target	=> $hookfile,
		content	=> $caseend
		order   => "79",
	}

  ::concat::fragment{"${hookfile}_release":
    target	=> $hookfile,
		content	=> template("pitlinz_virsh/hooks/qemu/80_release.erb"),
		order   => "80",
	}

  ::concat::fragment{"${hookfile}_release_end":
    target	=> $hookfile,
		content	=> $caseend
		order   => "89",
	}

  ::concat::fragment{"${hookfile}_status":
    target	=> $hookfile,
		content	=> template("pitlinz_virsh/hooks/qemu/90_status.erb"),
		order   => "90",
	}

  ::concat::fragment{"${hookfile}_status_end":
    target	=> $hookfile,
		content	=> $caseend
		order   => "98",
	}
  
  ::concat::fragment{"${hookfile}_footer":
    target	=> $hookfile,
		content	=> $caseend
		order   => "99",
	}

}
