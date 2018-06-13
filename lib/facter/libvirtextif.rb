Facter.add('libvirtextif') do
  confine :kernel => 'Linux'
  setcode do
    Facter::Core::Execution.exec("route -n | grep \"^0.0.0.0\" | cut -b73-999")
  end
end