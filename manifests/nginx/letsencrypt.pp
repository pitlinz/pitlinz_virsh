# install certbot to use letsencrypt
#
# @see https://serverfault.com/questions/768509/lets-encrypt-with-an-nginx-reverse-proxy
# @see https://serverfault.com/questions/768509/lets-encrypt-with-an-nginx-reverse-proxy
class pitlinz_virsh::nginx::letsencrypt(

) {
    if !defined(Pitlinz_servicestools::Ppa['python-certbot-apache']) {
        pitlinz_servicestools::ppa{'python-certbot-apache':
            ppaname => 'certbot/certbot'
        }
    }

    if !defined(Package['certbot']) {
        package{'certbot':
            ensure => latest
        }
    }
}
