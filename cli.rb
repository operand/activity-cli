require 'thor'
require 'json'
require 'socket'

class CLI < Thor
  # Ensure cli correctly reports failure due to bad command line arguments
  # See: https://github.com/rails/thor/wiki/Making-An-Executable
  def self.exit_on_failure?
    true
  end

  desc "start_process PATH ARGS", "Start a process with the given path and arguments"
  def start_process(path, *args)
    start_time = Time.now
    pid = spawn(path, *args)
    Process.detach(pid)
    process_info = {
      type: 'process_start',
      timestamp: start_time,
      username: current_username,
      process_name: File.basename(path),
      command_line: "#{path} #{args.join(' ')}",
      pid: pid
    }
    log_activity(process_info)
    puts "Started process #{pid}"
  end

  desc "create_new_file PATH", "Create a file at the specified path"
  def create_new_file(path)
    File.write(path, '')
    activity = {
      type: 'file_creation',
      timestamp: Time.now,
      path: path,
      action: 'create',
      username: current_username,
      process_name: current_process_name,
      process_command_line: current_process_command_line,
      pid: current_pid,
    }
    log_activity(activity)
    puts "Created file at #{path}"
  end

  desc "modify_file PATH", "Modify a file at the specified path"
  def modify_file(path)
    File.open(path, 'a') { |f| f.puts "Modified at #{Time.now}" }
    activity = {
      type: 'file_modification',
      timestamp: Time.now,
      path: path,
      action: 'modify',
      username: current_username,
      process_name: current_process_name,
      process_command_line: current_process_command_line,
      pid: current_pid,
    }
    log_activity(activity)
    puts "Modified file at #{path}"
  end

  desc "delete_file PATH", "Delete a file at the specified path"
  def delete_file(path)
    File.delete(path)
    activity = {
      type: 'file_deletion',
      timestamp: Time.now,
      path: path,
      action: 'delete',
      username: current_username,
      process_name: current_process_name,
      process_command_line: current_process_command_line,
      pid: current_pid,
    }
    log_activity(activity)
    puts "Deleted file at #{path}"
  end

  desc "network_activity DESTINATION PROTOCOL DATA", "Establish a network connection and transmit data"
  def network_activity(destination, protocol, data)
    start_time = Time.now
    socket = case protocol.downcase
            when 'tcp'
              TCPSocket.new(destination, 80)
            when 'udp'
              UDPSocket.new
            else
              raise ArgumentError, "Invalid protocol: #{protocol}"
            end
    source_port, source_address = Socket.unpack_sockaddr_in(socket.getsockname)
    if protocol.downcase == 'tcp'
      socket.write(data)
    else
      socket.send(data, 0, destination, 80)
    end
    socket.close

    activity = {
      type: 'network_activity',
      timestamp: start_time,
      destination: destination,
      data_sent: data.size,
      protocol: protocol,
      source_address: source_address,
      source_port: source_port,
      username: current_username,
      process_name: current_process_name,
      process_command_line: current_process_command_line,
      pid: current_pid,
    }
    log_activity(activity)
    puts "Sent data to #{destination}"
  end

  private

  def current_pid
    $$
  end

  def current_process_name
    $0
  end

  def current_process_command_line
    "#{$0} #{current_args.join(' ')}"
  end

  def current_args
    $*
  end

  def current_username
    `whoami`.strip
  end

  @@log_file = 'activity_log.jsonl'

  def log_activity(activity)
    File.open(@@log_file, 'a') do |file|
      file.puts(activity.to_json)
    end
  end
end
