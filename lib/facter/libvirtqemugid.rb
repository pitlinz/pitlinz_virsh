Facter.add('libvirtqemuguid') do
  confine :kernel => 'Linux'
  setcode do
    Facter::Core::Execution.exec("cat /etc/passwd | grep libvirt-qemu | cut -f4 -d':'")
  end
end