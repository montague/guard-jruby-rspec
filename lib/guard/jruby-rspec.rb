require 'guard'
require 'guard/guard'
require 'guard/rspec'

module Guard
  class JRubyRSpec < ::Guard::RSpec
    autoload :Runner,       'guard/jruby-rspec/runner'
    autoload :Inspector,    'guard/jruby-rspec/inspector'

    def initialize(watchers = [], options = {})
      @options = {
        :all_after_pass => true,
        :all_on_start   => true,
        :keep_failed    => true,
        :spec_paths     => ["spec"],
        :run_all        => {},
        :monitor_file   => ".guard-jruby-rspec"
      }.merge(options)
      @last_failed  = false
      @failed_paths = []

      default_watchers = [Watcher.new(@monitor)]
      if @custom_watchers.nil? or @custom_watchers.empty?
        default_watchers <<
            Watcher.new(%r{^(.+)\.rb$}) <<
            Watcher.new(%r{^(.+)\.(erb|haml)$})
      else
        watchers.each do |w|
          default_watchers << Watcher.new(w.pattern)
        end
      end

      @custom_watchers = watchers

      # touch the monitor file (lets the gjrspec know we're here)
      #File.open(@monitor, "w") {}

      # ideally we would bypass the Guard::RSpec initializer
      super(default_watchers, @options)

      @inspector = Inspector.new(@options)
      @runner = Runner.new(@options)

    end

    # Call once when guard starts
    def start
      UI.info "Guard::JRuby::RSpec is running, with RSpec!"
      run_all if @options[:all_on_start]
    end

    def run_on_change(raw_paths)
      reload_paths(raw_paths)

      unless @custom_watchers.nil? or @custom_watchers.empty?
        paths = []

        raw_paths.each do |p|
          @custom_watchers.each do |w|
            paths << w.call_action(w.match(p))
          end
        end
        super(paths)
      end
    end

    def reload_paths(paths)
      paths.each do |p| 
        if File.exists?(p) 
          if p == @options[:monitor_file]
            # begin
            #   pidfile = open(@options[:monitor_file], "r+")
            #   pid = pidfile.read

            #   run_all

            #   system("kill #{pid}") if (pid and !pid.empty?)
            # ensure
            #   @runner.cleanup
            # end
          else
            # reload the file
            load p 
          end
        end
      end
    end

  end
end

