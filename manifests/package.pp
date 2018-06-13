/**
 * calls package if not defined for $name
 */
define pitlinz_virsh::package(
    $ensure = latest
) {
    if !defined(Package["${name}"]) {
        package{"${name}": ensure => $ensure}
    }
}
