test_name "output help text" do
  step "Run with --help" do
    exe = "#{__dir__}/../../bin/ref_arch_setup --help"
    puts "it is #{exe}"
    foo = `#{exe}`
    puts "output is:"
    puts foo
  end
end
