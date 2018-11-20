#!/usr/bin/env ruby
require "net/http"
require "json"
require_relative '../../ruby_task_helper/lib/task_helper.rb'

class MyTask < TaskHelper

  PE_VERSIONS_URL = "https://puppet.com/misc/version-history".freeze

  # the minimum prod version supported by RAS
  MIN_PROD_VERSION = "2018.1.0".freeze

  def task(**kwargs)
    versions = fetch_supported_prod_versions

    puts "RAS supports the following PE versions:"
    puts versions
    puts

    result = {versions: versions}

    return result

  end

  def init
    @pe_versions_url = ENV["PE_VERSIONS_URL"] ? ENV["PE_VERSIONS_URL"] : PE_VERSIONS_URL
    @min_prod_version = ENV["MIN_PROD_VERSION"] ? ENV["MIN_PROD_VERSION"] : MIN_PROD_VERSION
  end

  def fetch_supported_prod_versions
    init
    versions_list = []
    puts "Checking Puppet Enterprise Version History: #{@pe_versions_url}"

    uri = URI.parse(@pe_versions_url)
    response = Net::HTTP.get_response(uri)
    validate_response(response)

    response.body.each_line do |line|
      if line.include?("<td>")
        contents = cell_contents(line)
        versions_list << contents if supported_version?(contents)
      end
    end

    return versions_list
  end

  def valid_version?(value)
    valid = value[/\p{L}/].nil?
    return valid
  end

  def cell_contents(line)
    contents = line[/#{Regexp.escape("<td>")}(.*?)#{Regexp.escape("</td>")}/m, 1]
    return contents
  end

  def supported_version?(value)
    supported = false

    if valid_version?(value)
      major_version = value.split(".")[0].to_i
      supported_version = @min_prod_version.split(".")[0].to_i
      supported = major_version >= supported_version ? true : false
    end

    return supported
  end

  def validate_response(res, valid_response_codes = ["200"],
      invalid_response_bodies = ["", nil])
    is_valid_response = false

    if res.nil?
      puts "Invalid response:"
      puts "nil"
      puts
    elsif !valid_response_codes.include?(res.code) ||
        invalid_response_bodies.include?(res.body)
      code = res.code.nil? ? "nil" : res.code
      body = res.body.nil? ? "nil" : res.body

      puts "Invalid response:"
      puts "code: #{code}"
      puts "body: #{body}"
      puts
    else
      is_valid_response = true
    end

    raise "Invalid response" unless is_valid_response

    return is_valid_response
  end


end

MyTask.run if __FILE__ == $0





