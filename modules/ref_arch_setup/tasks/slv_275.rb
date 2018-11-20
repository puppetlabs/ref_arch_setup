#!/usr/bin/env ruby
require_relative "../../ruby_task_helper/lib/task_helper.rb"

# PE Versions Task using Ruby Task Helper
class ExampleTask < TaskHelper
  def task(message: nil, **_kwargs)
    { greeting: "Hi, the message is #{message}" }
  end
end

ExampleTask.run if $PROGRAM_NAME == __FILE__
