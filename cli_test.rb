require 'minitest/autorun'
require 'json'
require 'tempfile'
require_relative 'platforms/nix' # TODO: add support for other platforms

class CLITests < Minitest::Test
  def setup
    @log_file = Tempfile.new('activity_log')
    NixCLI.class_variable_set(:@@log_file, @log_file.path)
  end

  def teardown
    @log_file.close
    @log_file.unlink
  end

  def test_start_process
    path = 'true'
    args = ['arg1', 'arg2']
    assert_output(/Started process \d+\n/) do
      NixCLI.start("start_process #{path} #{args.join(' ')}".split)
    end
    assert_logged_activity(
      type: 'process_start',
      timestamp: /.+/,
      username: /.+/,
      process_name: 'true',
      command_line: "#{path} #{args.join(' ')}",
      pid: /\d+/,
    )
  end

  def test_create_new_file
    path = 'tmp/test_file.txt'
    assert_output("Created file at #{path}\n") do
      NixCLI.start("create_new_file #{path}".split)
    end
    assert_logged_activity(
      type: 'file_creation',
      timestamp: /.+/,
      path: path,
      username: /.+/,
      process_name: /.+/,
      process_command_line: /.+/,
      pid: /\d+/,
    )
  end

  def test_modify_file
    path = 'tmp/test_file.txt'
    File.write(path, '')
    assert_output("Modified file at #{path}\n") do
      NixCLI.start("modify_file #{path}".split)
    end
    assert_logged_activity(
      type: 'file_modification',
      timestamp: /.+/,
      path: path,
      username: /.+/,
      process_name: /.+/,
      process_command_line: /.+/,
      pid: /\d+/,
    )
  end

  def test_delete_file
    path = 'tmp/test_file.txt'
    File.write(path, '')
    assert_output("Deleted file at #{path}\n") do
      NixCLI.start("delete_file #{path}".split)
    end
    assert_logged_activity(
      type: 'file_deletion',
      timestamp: /.+/,
      path: path,
      username: /.+/,
      process_name: /.+/,
      process_command_line: /.+/,
      pid: /\d+/,
    )
  end

  def test_network_activity
    host = 'example.com'
    port = 80
    protocol = 'TCP'
    data = 'testdata'
    assert_output("Sent data to #{host}:#{port}\n") do
      NixCLI.start("network_activity #{host} #{port} #{protocol} #{data}".split)
    end
    assert_logged_activity(
      type: 'network_activity',
      timestamp: /.+/,
      host: host,
      port: port.to_s,
      data_sent: data.size,
      protocol: protocol,
      source_address: /.+/,
      source_port: /\d+/,
      username: /.+/,
      process_name: /.+/,
      process_command_line: /.+/,
      pid: /\d+/,
    )
  end

  private

  def assert_logged_activity(expected_activity)
    log_entries = []
    @log_file.rewind
    @log_file.each_line do |line|
      log_entries << JSON.parse(line)
    end
    # Find matching entry based on provided fields in expected_activity
    matching_entry = log_entries.find do |entry|
      expected_activity.all? do |key, value|
        if value.is_a?(Regexp)
          entry[key.to_s].to_s =~ value || entry[key.to_sym].to_s =~ value
        else
          entry[key.to_s] == value || entry[key.to_sym] == value
        end
      end
    end
    assert matching_entry, "Expected activity not found in log. Expected: #{expected_activity}"
  end
end
