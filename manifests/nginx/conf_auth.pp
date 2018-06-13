/**
 * add auth to config
 *
 */
define udm_host2::nginxproxy::conf_auth(
    $target	= undef,
    $user	= undef,
    $passwd	= undef,
) {
   	$pwdFile = "/etc/nginx/auth/${name}.password"

	exec {"nginx_${name}_passwd":
		command => "/usr/bin/htpasswd -cb ${pwdFile} ${user} ${passwd}",
		creates => "${pwdFile}",
		require => File["/etc/nginx/auth"],
	}

	concat::fragment{"${name}_auth":
		    target	=> "${target}",
			content	=> "\n\tauth_basic ${name};\n\tauth_basic_user_file ${pwdFile};\n\n",
			order   => "101",
	}

}
