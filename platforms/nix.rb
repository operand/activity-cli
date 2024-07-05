require 'socket'
require_relative 'base'

class NixCLI < Base
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

  desc "network_activity HOST PORT PROTOCOL DATA", "Establish a network connection and transmit data"
  def network_activity(host, port, protocol, data)
    start_time = Time.now
    socket = case protocol.downcase
            when 'tcp'
              TCPSocket.new(host, port)
            when 'udp'
              UDPSocket.new
            else
              raise ArgumentError, "Invalid protocol: #{protocol}"
            end
    if protocol.downcase == 'tcp'
      source_port, source_address = Socket.unpack_sockaddr_in(socket.getsockname)
      socket.write(data)
    else
      socket.send(data, 0, host, port)
      # get the source info after sending data
      source_port, source_address = Socket.unpack_sockaddr_in(socket.getsockname)
    end
    socket.close

    activity = {
      type: 'network_activity',
      timestamp: start_time,
      host: host,
      port: port,
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
    puts "Sent data to #{host}:#{port}"
  end
end
