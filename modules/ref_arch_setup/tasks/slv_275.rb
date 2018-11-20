#!/usr/bin/env ruby
require_relative '../../ruby_task_helper/lib/task_helper.rb'

class MyTask < TaskHelper
  def task(message: nil, **kwargs)
    { greeting: "Hi, the message is #{message}" }
  end
end

MyTask.run if __FILE__ == $0






