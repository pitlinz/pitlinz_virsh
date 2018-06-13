Facter.add('libvirtqemuuid') do
  confine :kernel => 'Linux'
  setcode do
    Facter::Core::Execution.exec("cat /etc/passwd | grep libvirt-qemu | cut -f3 -d':'")
  end
end