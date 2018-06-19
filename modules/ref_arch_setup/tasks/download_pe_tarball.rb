#!/usr/bin/env ruby
require 'json'
require 'uri'
require 'open-uri'
require 'fileutils'

# Initialize the instance variables with the specified parameters or default values
#
# @author Bill Claytor
#
# @return [true,false] Based on success parsing JSON input
def init()
  success = true
  begin
    params = JSON.parse(STDIN.read)
    @url = params['url']
    @destination = params['destination'] || "/tmp/ref_arch_setup"
  rescue JSON::ParserError
    success = false
    puts "Error parsing JSON input!"
    puts
  end
  success
end

# Verify that the URL is either "http" or "https"
#
# @author Bill Claytor
#
# @param [string] url The URL to verify
#
# @return [true,false] Based on the verification outcome
def is_valid_url?(url)
  valid = false
  if url =~ /\A#{URI::regexp(['http', 'https'])}\z/
    valid = true
  else
    puts "Invalid URL: #{url}"
  end
  valid
end

# Verify that the extension is ".gz"
#
# @author Bill Claytor
#
# @param [string] url The URL to verify
#
# @return [true,false] Based on the verification outcome
def is_valid_extension?(url)
  valid = false
  extension = File.extname(url)
  if extension == ".gz"
    valid = true
  else
    puts "Invalid extension: #{extension} for URL: #{url}. Extension must be .gz"
  end
  valid
end

# Attempt to create the specified destination directory if it does not already exist
#
# @author Bill Claytor
#
# @param [string] destination The folder to verify or attempt to create
#
# @return [true,false] Based on the existence of the specified directory
def ensure_destination(destination)

  # don't do anything unless the destination doesn't exist
  if !File.directory?(destination)
    puts "Destination directory '#{destination}' does not exist; attempting to create it"

    # TODO: handle exception
    FileUtils::mkdir_p destination

    puts "Destination #{destination} could not be created" unless File.directory?(destination)

  end

  # return the current status
  File.directory?(destination)
end

# Download the specified URL to the specified destination
#
# @author Bill Claytor
#
# @param [string] url The URL for the file to download
# @param [string] destination_path The path where the file should be downloaded
#
# @return [true,false] Based on the success of the download and verification
def download(url, destination_path)
  puts "Downloading '#{url}' to '#{destination_path}'"
  puts

  dl = open(url)
  IO.copy_stream(dl, destination_path)

  verify_download(destination_path)
end

# Verify that the provided file signature matches the downloaded file
#
# @author Bill Claytor
#
# @param [string] path Path to the file to verify
#
# @return [true,false] Based on the success of verification
def verify_download(path)
  # TODO: implement verification
  is_valid = true
  puts "Verifying '#{path}'"
  puts

  is_valid
end

# Validate the provided input
#
# @author Bill Claytor
#
# @return [true,false] Based on the success of validation
def is_valid_input?()
  is_valid_url?(@url) && is_valid_extension?(@url) && ensure_destination(@destination)
end

# Encapsulate the high-level task functionality
#
# @author Bill Claytor
#

# @return [0,1] Based on the exit status for the bolt task
def execute_task()
  exit_code = 0
  filename = File.basename(@url)
  destination_path = "#{@destination}/#{filename}"

  # TODO: remove or keep this output?
  puts "URL: #{@url}"
  puts "Destination: #{@destination}"
  puts "Filename: #{filename}"
  puts "Destination path: #{destination_path}"
  puts

  success = download(@url, destination_path)

  if (!success)
    exit_code = 1
    puts "Error downloading #{@url} to #{destination_path}"
  end
  exit_code
end

# Isolate the task code and prevent execution via RSpec
#
# Run the bolt task by specifying the url and optionally a destination directory
# The task can be run on either localhost or a remote host
#
# From the ref_arch_setup directory:
# bolt task run ref_arch_setup::download_pe_tarball url=https://example.com/example.tar.gz directory=/tmp/ras --modulepath ./modules --nodes remote_or_localhost --user user_to_run_as
#
# @return [0,1] Based on the exit status for the bolt task
if $0 == __FILE__
  exit_code = 0

  begin
    if init && is_valid_input?
      exit_code = execute_task
    else
      exit_code = 1
      puts "Invalid input; exiting!"
      puts
    end

  rescue Exception => e
    exit_code = 1
    puts "Exception encountered: #{e.message}"
    puts
    result[:_error] = { msg: e.message,
                        kind: "ref_arch_setup::download_pe_tarball/task-error",
                        details: { class: e.class.to_s },
    }
  end

  exit exit_code
end
