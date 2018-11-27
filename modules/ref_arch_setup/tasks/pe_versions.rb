#!/usr/bin/env ruby
require "net/http"
require "json"
require_relative "../../ruby_task_helper/lib/task_helper.rb"

# PE Versions example task using Ruby Task Helper
class VersionsTask < TaskHelper
  # the 'Puppet Enterprise Version History' url
  PE_VERSIONS_URL = "https://puppet.com/misc/version-history".freeze

  # the minimum prod version supported by RAS
  MIN_PROD_VERSION = "2018.1.0".freeze

  # The task helper task
  #
  # @author Bill Claytor
  #
  # @param [Hash] _kwargs A hash of params for the task
  #
  # @return [Array] The versions list
  #
  # @example
  #   result = task(_kwargs)
  #
  def task(**_kwargs)
    versions = fetch_supported_prod_versions

    puts "RAS supports the following PE versions:"
    puts versions
    puts

    result = { versions: versions }

    return result
  end

  # Initializes the pe_versions options
  #
  # @author Bill Claytor
  #
  # @return [void]
  #
  # @example
  #   init
  #
  def init
    @pe_versions_url = ENV["PE_VERSIONS_URL"] ? ENV["PE_VERSIONS_URL"] : PE_VERSIONS_URL
    @min_prod_version = ENV["MIN_PROD_VERSION"] ? ENV["MIN_PROD_VERSION"] : MIN_PROD_VERSION
  end

  # Fetches the list of PE versions from the 'Puppet Enterprise Version History'
  # supported by RAS
  #
  # @author Bill Claytor
  #
  # @return [Array] The versions list
  #
  # @example
  #   versions_list = fetch_prod_versions
  #
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

  # Determines whether the specified cell contents contains a valid PE version
  #
  # @author Bill Claytor
  #
  # @param [string] cell_contents The specified cell contents
  #
  # @return [true, false] Whether the specified value matches the PE version format
  #
  # @example
  #   result = valid_version?(cell_contents)
  #
  def valid_version?(cell_contents)
    valid = cell_contents[/\p{L}/].nil?
    return valid
  end

  # Extracts the cell contents from the specified line
  #
  # @author Bill Claytor
  #
  # @param [string] line A line containing an HTML table cell ("<td>" ... "</td>")
  #
  # @return [string] The contents of the cell
  #
  # @example
  #   cell_contents = cell_contents(line)
  #
  def cell_contents(line)
    contents = line[/#{Regexp.escape("<td>")}(.*?)#{Regexp.escape("</td>")}/m, 1]
    return contents
  end

  # Determines whether the specified value is a PE version supported by RAS
  #
  # @author Bill Claytor
  #
  # @param [string] value The specified value
  #
  # @return [true, false] Whether the specified value matches the PE version format
  #
  # @example
  #   result = valid_version?(value)
  #
  def supported_version?(value)
    supported = false

    if valid_version?(value)
      major_version = value.split(".")[0].to_i
      supported_version = @min_prod_version.split(".")[0].to_i
      supported = major_version >= supported_version ? true : false
    end

    return supported
  end

  # Determines whether the response is valid
  #
  # @author Bill Claytor
  #
  # @param [Net::HTTPResponse] res The HTTP response to evaluate
  # @param [Array] valid_response_codes The list of valid response codes
  # @param [Array] invalid_response_bodies The list of invalid response bodies
  #
  # @raise [RuntimeError] If the response is not valid
  #
  # @return [true,false] Based on whether the response is valid
  #
  # @example
  #   valid = validate_response(res)
  #   valid = validate_response(res, ["200", "123"], ["", nil])
  #
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
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
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end

VersionsTask.run if $PROGRAM_NAME == __FILE__
