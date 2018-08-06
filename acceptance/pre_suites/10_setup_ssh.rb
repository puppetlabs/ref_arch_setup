test_name "set up ssh between controller and target-master" do
  step "create ssh key" do
    on controller, "yes | ssh-keygen -q -t rsa -b 4096 -f /root/.ssh/id_rsa -N '' -C 'ras'"
  end

  step "put keys on the target-master" do
    hosts = [target_master]
    results = on controller, "cat /root/.ssh/id_rsa.pub"
    key = results.stdout.strip
    command = "echo \"#{key}\" >> /root/.ssh/authorized_keys"
    on hosts, command
  end

  # TODO: remove once bolt ssh issue is resolved
  step "copy bolt config to controller to prevent ssh host verification" do
    scp_to(controller, "#{__dir__}/../../fixtures/.puppetlabs", ".puppetlabs")
  end
end
