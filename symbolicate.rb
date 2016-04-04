#!/usr/bin/ruby

require 'pathname'

class CrashSymbolicator

  def initialize(dysm_path)
    @dysm_path=dysm_path
  end

  def setup_developer_environment
    # Checking developer path
    developer_path = `/usr/bin/xcode-select -print-path`.strip
    required_developer_path = '/Applications/Xcode.app/Contents/Developer/'

    if developer_path != required_developer_path
      puts "We have to change Xcode Developer path to \"#{required_developer_path}\""
      `sudo /usr/bin/xcode-select -switch #{required_developer_path}`
      puts "Developer path set to: #{developer_path}"
    end


    # Export develoepr dir variable
    ENV['DEVELOPER_DIR'] = developer_path
  end

  def get_symbolicatecrash_path
    symbolicate_crash_app_path = '/Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/Versions/A/Resources/symbolicatecrash'
    unless Pathname.new(symbolicate_crash_app_path).exist?
      symbolicate_crash_app_path = `find /Applications/Xcode.app -name symbolicatecrash -type f`.strip
    end
    puts "Found symbolicatecrash at path: #{symbolicate_crash_app_path}"
    symbolicate_crash_app_path
  end

  def prepare_symbolicatecrash
    unless Pathname.new(self.local_symbolicatecrash_path).exist?
      # 1. Coping system to local path
      `cp #{self.get_symbolicatecrash_path} #{self.local_symbolicatecrash_path}`

      # 2. Applying deadlock patch
      `curl -o #{self.local_symbolicatecrash_patch_path} https://raw.githubusercontent.com/zqxiaojin/OptSymbolicatecrash/master/fix_dead_loop.patch`
      `patch #{self.local_symbolicatecrash_path} #{self.local_symbolicatecrash_patch_path}`
    end
  end

  def resources_dir
    `mkdir -p #{File.dirname(__FILE__)}/resources`
    "#{File.dirname(__FILE__)}/resources"
  end

  def local_patch_path
    "#{self.resources_dir}/fix_dead_loop.patch"
  end

  def local_symbolicatecrash_path
    "#{self.resources_dir}/symbolicatecrash"
  end

  def symbolicte(input_path, output_path = nil)
    self.setup_developer_environment
    self.prepare_symbolicatecrash

    unless output_path
      output_path = input_path
    end

    tmp_file = File.join(File.dirname(output_path), (File.basename(output_path) + '.tmp'))

    `#{self.local_symbolicatecrash_path} #{input_path} #{@dysm_path} > #{tmp_file}`

    `rm -f #{output_path}`
    `mv #{tmp_file} #{output_path}`
  end

end


#######

path_to_crash = ARGV[0]
dir = Pathname.new(path_to_crash).dirname
crash_name = Pathname.new(path_to_crash).basename.to_s
path_to_dsym = File.join(dir, `ls #{dir} | grep dSYM`.strip)
output_path = File.join(dir, ('Symbolicated-' + crash_name))

symbolicator = CrashSymbolicator.new(path_to_dsym)
symbolicator.symbolicte(path_to_crash, output_path)
