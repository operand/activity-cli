require 'thor'
require 'json'

class Base < Thor
  # Ensure cli correctly reports failure due to bad command line arguments
  # See: https://github.com/rails/thor/wiki/Making-An-Executable
  def self.exit_on_failure?
    true
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
