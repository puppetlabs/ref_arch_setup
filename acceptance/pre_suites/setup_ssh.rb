test_name "install RAS on controller" do

  step "create key for controller to talk to target-master" do

    on controller, "yes | ssh-keygen -q -t rsa -b 4096 -f /root/.ssh/id_rsa -N '' -C 'ras'"

  end

  step "put keys on the target-master" do
    results = on controller, "cat /root/.ssh/id_rsa.pub"
    key = results.stdout.strip
    on target_master, "echo \"#{key}\" >> /root/.ssh/authorized_keys"
  end

  step "copy bolt config to controller to prevent ssh host verification" do
    scp_to(controller, "#{__dir__}/../../fixtures/.puppetlabs", ".puppetlabs")
  end

end
