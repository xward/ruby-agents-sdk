require 'singleton'
require 'rspec'
require 'thread'
require 'monitor'
require 'timeout'

require_relative 'formatter'

# TODO this class assumes (formatter etc.) that tests were built only for one agent.
# Solutions:
# * one RSpec call -> simple wrapper, but won't be able to separate the tests in the GUI
# * test one agent only -> ...
# ***** hash of formatters initialized at object creation (but not of reporters) *****

# TODO the formatter must send back a valid represnetaiton even for tests that are not started

module Tests

  # Provides a simple interface to run tests, stop them, and collect the results
  # This class is a thread-safe singleton: call {TestRunner.instance} to retrieve the class instance.
  # Internally, it manages a thread that run Rspec.
  class TestsRunner

    include Singleton

    def initialize
      @tester_thread = nil
      @lock = Monitor.new # reentrant lock
      @formatter_lock = Mutex.new
      @formatters = []
    end

    # Run the tests
    # @param [Hash{String => String}] agent_paths a hash mapping the tested agent name to the path to its test folder on the filesystem
    def start_tests(agent_paths)
      @formatter_lock.synchronize do
        @formatters = agent_paths.each_with_object({}) { |(name, path), hash| hash[name] = Formatter.new($stdout, name) }
      end
      @agent_paths = agent_paths
      @lock.synchronize do
        stop_tests
        CC.logger.info("Tests started")
        create_tester_thread(@agent_paths)        
      end      
    end

    # Abort any currently running tests. Does nothing if no tests are running.
    def stop_tests
      @lock.synchronize do 
        interrupt_tests
      end
    end

    # @param [Hash{String => Integer}] filter an optional filter. Keys are agent names, values are the minimum exmple index to return for the agent.
    #                                  Ignored if the status of the test is not "started". If "aborted", could be ignored as well.
    # @return [Hash] a frozen hash of the current test status. Keys are agent names. If no tests were started before, returns {'status' => 'no tests'}
    def get_status(filter = nil)
      @formatter_lock.synchronize do
        if @formatters.size == 0
          # no tests were started, ever
          return {"status" => "no tests"}
        else
          return @formatters.each_with_object({}) do |(formatter_name, formatter), hash|
            if filter.nil?
              filter_index = -1
            else
              fiter_index = filter[formatter_name]
            end
            hash[formatter_name] = formatter.get_status(filter)
          end
        end
      end 
    end

    private

    # Should be called with the lock acquired.
    # @param [Hash{String => String}] agents_to_test a hash with the form agent_name => path_to_the_agent_root_directory
    def create_tester_thread(agents_to_test)
      @test_thread = Thread.new(agents_to_test) do |agents_to_test| # todo: handle multiple agents at the same time
          agents_to_test.each do |agent_name, path|
            config = RSpec.configuration
            reporter = RSpec::Core::Reporter.new(@formatters[agent_name])
            config.instance_variable_set(:@reporter, reporter)
            CC.logger.info("Running tests for agent #{agent_name}")
            begin
              RSpec::Core::Runner.run([File.expand_path(path)])
            rescue StandardError => e
              CC.logger.info("Caught exception when running tests for agent #{agent_name}: #{e.to_s}.")
              @formatters[agent_name].set_exception(e)
            end
            break if @aborting_tests
          end
        end
    end

    def interrupt_tests 
      # if tests are not running, this method does nothing relevant
      begin
        Timeout.timeout(5) do
          Rspec.wants_to_quit = true
          @aborting_tests = true
          @test_thread.join unless @test_thread.nil?
        end
      rescue Timeout::Error => e
        CC.logger.warning("Stopping test gracefully taking too long, killing tests thread.")
        Thread.kill(@test_thread)
      end
      @formatters.each do |name, formatter|
        formatter.close
      end
      @aborting_tests = false
      Rspec.wants_to_quit = false
      CC.logger.info("Tests stopped.")
    end

  end

end