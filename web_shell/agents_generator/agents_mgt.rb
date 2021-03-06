#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

require 'fileutils'
require 'yaml'
require 'securerandom'

require 'bundler'

module AgentsGenerator

  require_relative 'gemfile_mergator'

  def source_path
    @ROOT_PATH_AGENT_MGT ||= File.expand_path("..", __FILE__)
  end

  def workspace_path
    @ROOT_PATH_WORKSPACE ||= "#{source_path}/../../cloud_agents"
  end

  def package_output_path
    @ROOT_PATH_OUTPUT_PACKAGE ||= "#{source_path}/../../output"
  end

  def generated_rb_path
    @GENERATED_PATH ||= File.expand_path("#{source_path}/cloud_agents_generated")
  end

  def protogen_bin_path
    @PROTOGEN_BIN_PATH ||= "#{source_path}/exts/protogen/protocol_generator/"
  end

  def sdk_utils_path
    @SDK_UTILS_PATH ||= "#{generated_rb_path}/sdk_utils"
  end

  def clean_name(name)
    name.gsub('-','_')
  end

  #########################################################################################################
  ## compile

  def add_to_rapport(txt)
    @AgentsGenerator_rapport_generation += "#{txt}\n"
    puts txt
  end

  def generate_agents_protogen # we could do it into generate_agents but we separate generations to track errors easily
    @AgentsGenerator_rapport_generation = ""

    FileUtils.mkdir_p("#{generated_rb_path}")

    agents_to_run = get_run_agents

    # protogen
    Bundler.with_clean_env do
      agents_to_run.each do |agent|

        PUNK.start('a')

        if !(File.exist?("#{workspace_path}/#{agent}/config/protogen.json"))
          CC.logger.info("Agent '#{agent}' protogen.json file not found. Skip.")
          next
        end

        ptc = File.read("#{workspace_path}/#{agent}/config/protogen.json")
        if ptc == ""
          CC.logger.info("Agent '#{agent}' protogen.json empty. Skip.")
          next
        end

        # generate compil conf
        compil_opt = {
          "plugins" => ["mdi_sdk_vm_server_ruby"],
          "agent_name" => "#{agent}",
          "server_output_directory" => "#{generated_rb_path}/protogen_#{agent}",
          "user_callbacks" => "#{workspace_path}/#{agent}/protogen"
        }
        File.open('/tmp/protogen_conf.json', 'w') { |file| file.write(compil_opt.to_json)}

        # create dir for ruby side code
        FileUtils.mkdir_p(compil_opt['server_output_directory'])

        # bundle install protogen
        command = "cd #{protogen_bin_path}; bundle install"
        output = `#{command}`
        CC.logger.debug("protogen bundle install:\n #{output}\n\n")

        # run protogen generation
        command = "cd #{protogen_bin_path}; bundle exec ruby protogen.rb #{workspace_path}/#{agent}/config/protogen.json /tmp/protogen_conf.json"
        CC.logger.debug "running command #{command} :"
        output = `#{command} 2>&1`

        exit_code = $?.clone.exitstatus

        CC.logger.debug("Protogen output:\n #{output}\n\n")

        CC.logger.info("Protogen exit code: #{exit_code}")

        if exit_code != 0 # non-zero exit code means error. We abort on all errors except code 4 and 5
          # see protocol_generator/error.rb for the signification of error codes
          CC.logger.warn("Protogen returned non-zero status code (non-zero status code means an error occured).")
          if exit_code == 4  # protocol file not found
            CC.logger.warn("Protocol file not found for #{agent} at 'config/protogen.json', Protogen will not be available for this agent.")
          elsif exit_code == 5 # protocol file empty
            CC.logger.warn("Protocol file empty for #{agent} at 'config/protogen.json', Protogen will not be available for this agent.")
          else
            CC.logger.error("Protogen fatal error, see Protogen output for details.")
            PUNK.end('a','ko','',"SERVER Protogen generation for agent #{agent} failed")
            raise "Protogen generation failed for agent #{agent}"
          end
        end

        CC.logger.info("Protogen generation for #{agent} done.")
        PUNK.end('a','ok','',"SERVER generated Protogen for agent #{agent}")

        # copy documentation
        FileUtils.mkdir_p("#{workspace_path}/#{agent}/doc/protogen")
        FileUtils.cp_r(Dir["#{source_path}/cloud_agents_generated/protogen_#{agent}/doc/*"],"#{workspace_path}/#{agent}/doc/protogen/")
        CC.logger.info("Protogen doc deployed for #{agent} \n")
      end # each agent
    end # Bundler with clean env

  end


  # to be purged
  # def generate_agents
  #   @AgentsGenerator_rapport_generation = ""

  #   FileUtils.mkdir_p("#{generated_rb_path}")

  #   add_to_rapport("\n========= generate_agents start ===============")

  #   # get agents to run
  #   agents_to_run = get_run_agents

  #   add_to_rapport("generate_agents of #{agents_to_run.join(', ')}")

  #   agents_generated_code = ""

  #   template_agent_src = File.read("#{source_path}/template_agent.rb_")

  #   # template generation
  #   agents_to_run.each do |agent|
  #     clean_class_name = clean_name("#{agent}")
  #     downcased_class_name = clean_class_name.downcase

  #     template_agent = template_agent_src.clone
  #     template_agent.gsub!('XX_PROJECT_NAME',"#{agent}")
  #     template_agent.gsub!('XX_DOWNCASED_CLEAN_PROJECT_NAME',downcased_class_name)
  #     template_agent.gsub!('XX_CLEAN_PROJECT_NAME',clean_class_name)
  #     agents_generated_code += template_agent

  #     agents_generated_code += "# call new to auto subscribe\n"
  #     agents_generated_code += "Agent_#{clean_class_name}.new\n\n\n"
  #   end
  #   agents_generated_code += "\n\n\n\n"

  #   # Tests runner
  #   # agents_generated_code += "def run_tests(agents)\n"
  #   # agents_to_run.each do |agent|
  #   #   agents_generated_code += "  results = $#{agent}_initial.run_tests\n"
  #   # end
  #   # agents_generated_code += "end\n\n"

  #   File.open("#{generated_rb_path}/generated.rb", 'w') { |file| file.write(agents_generated_code) }

  #   # Generate sdk_api.rb
  #   template_sdk_api_generated_code = ''
  #   template_api_src = File.read("#{source_path}/template_sdk_api.rb_")
  #   FileUtils.mkdir_p("#{sdk_utils_path}")

  #   agents_to_run.each do |agent|
  #     clean_class_name = clean_name("#{agent}")
  #     downcased_class_name = clean_class_name.downcase
  #     template_sdk_api = template_api_src.clone
  #     template_sdk_api.gsub!('XX_PROJECT_NAME',"#{agent}")
  #     template_sdk_api.gsub!('XX_CLEAN_PROJECT_NAME',clean_class_name)
  #     template_sdk_api.gsub!('XX_DOWNCASED_CLEAN_PROJECT_NAME',downcased_class_name)
  #     template_sdk_api.gsub!('XX_PROJECT_ROOT_PATH',"#{workspace_path}/#{agent}")
  #     template_sdk_api_generated_code += template_sdk_api
  #     template_sdk_api_generated_code += "\n\n"
  #   end

  #   File.open("#{sdk_utils_path}/sdk_api.rb", 'w') { |file| file.write(template_sdk_api_generated_code)}


  #   add_to_rapport("Templates generated done\n")

  #   generate_Gemfile


  #   # check agent name here, restore if note here
  #   agents_to_run.each { |agent|
  #     if !(File.exist?("#{workspace_path}/#{agent}/.agent_name"))
  #       File.open("#{workspace_path}/#{agent}/.agent_name", 'w') { |file| file.write(agent) }
  #     end
  #   }

  #   # check config exist
  #   agents_to_run.each { |agent|
  #     if !(File.exist?("#{workspace_path}/#{agent}/config/#{agent}.yml"))
  #       restore_default_config(agent)
  #     end
  #   }

  #   add_to_rapport("Config checked\n")

  #   #  generad dyn channel list
  #   dyn_channels = Hash.new()
  #   channel_int = 1000
  #   agents_to_run.each { |agent|
  #     channels = get_agent_dyn_channel(agent)
  #     channels.each { |chan|
  #       dyn_channels[chan] = channel_int
  #       channel_int +=1
  #     }
  #   }

  #   File.open("#{source_path}/cloud_agents_generated/dyn_channels.yml", 'w+') { |file| file.write(dyn_channels.to_yaml) }

  #   add_to_rapport("Dynamic channel merged\n")

  #   add_to_rapport('generate_agents done')

  #   @AgentsGenerator_rapport_generation
  # end

  def generate_Gemfile

    # get agents to run
    agents_to_run = get_run_agents


    # Merge Gemfile
    agents_Gemfiles = []
    agents_to_run.each do |agent|
      agents_Gemfiles << get_agent_Gemfile_content(agent)
    end
    master_GemFile = File.read("#{source_path}/../local_cloud/Gemfile.master")

    gemFile_content = merge_gem_file(master_GemFile, agents_Gemfiles)
    puts "GemFile_content =\n #{gemFile_content}\n\n"

    File.open("#{source_path}/../local_cloud/Gemfile", 'w') { |file| file.write(gemFile_content) }

  end


  def generated_get_dyn_channel
    YAML::load(File.open("#{source_path}/cloud_agents_generated/dyn_channels.yml"))
  end


  def generated_get_agents_whenever_content
    agents_to_run = get_run_agents
    agents_whenever=''

    agents_to_run.each { |agent|
      agents_whenever += get_agent_whenever_content(agent) + "\n"
    }
    agents_whenever
  end

  #########################################################################################################
  ## agent mgt

  # @params [String] name name of the agent (must be lowercase, ASCII only)
  # @params [String] protogen_package_name if nil, the new agent will have its new Protogen file empty. If a String, create a default Protogen template using the given package name.
  # @return `true` if success
  def create_new_agent(name, protogen_package_name = nil)

    #todo filter name character, only letter and '_'
    name.gsub!(' ', '_')
    name.gsub!('-', '_')

    #verify if folder/file already exist
    return false if File.exists?("#{workspace_path}/#{name}")

    project_path = "#{workspace_path}/#{name}"
    p "Creating project #{name} ..."

    #create directory
    Dir::mkdir(project_path)

    # create file guid
    File.open("#{project_path}/.mdi_cloud_agent_guid", 'w') { |file| file.write(generate_new_guid()) }

    # init agent name
    File.open("#{project_path}/.agent_name", 'w') { |file| file.write(name) }

    #copy sample project
    FileUtils.cp_r(Dir["#{source_path}/sample_agent/*"],"#{project_path}")

    #rename config file
    FileUtils.mv("#{project_path}/config/config.yml", "#{project_path}/config/#{name}.yml")


    # Update protogen template file
    if protogen_package_name.nil?
      # Delete template protogen file content
      File.open("#{project_path}/config/my_protocol.protogen", 'w') { |file| file.write('') }
    else
      template =  File.read("#{project_path}/config/my_protocol.protogen")
      template.gsub!("@PROJECTNAME@", "#{name.capitalize}_protocol")
      template.gsub!("@PACKAGE@", protogen_package_name)
      File.open("#{project_path}/config/my_protocol.protogen", 'w') { |file| file.write(template) }
    end

    # Match and replace name project stuff in content
    match_and_replace_in_folder(project_path,"XXProjectName",name)

    return true
  end

  def restore_default_config(name)
    puts "restore_default_config for agent #{name}"
    project_path = "#{workspace_path}/#{name}"
    FileUtils.cp("#{source_path}/sample_agent/config/config.yml", "#{project_path}/config/#{name}.yml")
    match_and_replace_in_folder("#{project_path}/config","XXProjectName", name)
  end


  def add_agent_to_run_list(name)
   return false unless is_agent_valid(name)
   run_list = get_run_agents
   run_list.delete(name)
   run_list.push(name)
   set_run_agents(run_list)
  end

  def remove_agent_from_run_list(name)
   run_list = get_run_agents
   run_list.delete(name)
   set_run_agents(run_list)
  end

  #return [name]
  def get_available_agents()
    dirs = get_dirs("#{workspace_path}")
    remove_unvalid_agents(dirs)
  end

  #return [name]
  def get_run_agents()
    #read .agents_to_run file (if not exist create one)
    FileUtils.touch("#{source_path}/.agents_to_run")
    agents = File.read("#{source_path}/.agents_to_run").split(';')

    #for each verify that agent is still here and valid
    remove_unvalid_agents(agents)
  end

  # return an array of string
  def get_agent_dyn_channel(name)
    return [] unless File.directory?("#{workspace_path}/#{name}")
    cnf = {}
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    end

    channels = cnf['Dynamic_channel_str']
    channels = cnf['dynamic_channel_str'] if channels == nil

    if channels.is_a? String
      [] << channels
    elsif channels.is_a? Hash
      channels
    else
      p "get_agent_dyn_channel: unkown format of #{channels} for dynchannels of agent #{name}"
    end
  end


  def get_agent_is_sub_presence(name)
    return nil unless File.directory?("#{workspace_path}/#{name}")
    cnf = {}
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    end

    cnf['subscribe_presence']
  end

  def get_agent_is_sub_message(name)
    return nil unless File.directory?("#{workspace_path}/#{name}")
    cnf = {}
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    end

    cnf['subscribe_message']
  end

  def get_agent_is_sub_track(name)
    return nil unless File.directory?("#{workspace_path}/#{name}")
    cnf = {}
    if File.exist?("#{workspace_path}/#{name}/config/#{name}.yml")
      cnf = YAML::load(File.open("#{workspace_path}/#{name}/config/#{name}.yml"))['development']
    end

    cnf['subscribe_track']
  end




  #########################################################################################################
  ## Basic tools

  def get_sdk_version
    @sdk_version ||= File.read('../../VERSION')
  end

  def generate_new_guid
    get_sdk_version + ";" + SecureRandom.base64
  end

  def get_dirs(path)
    Dir.entries(path).select {|entry| File.directory? File.join(path,entry) and !(entry =='.' || entry == '..') }
  end

  def get_files(path)
    Dir.entries(path).select {|f| File.file? File.join(path,f)}
  end

  #return true if valid todo: add more case that return false (gem file dynchannel etc), + print when rejected
  def is_agent_valid(name)
    return false unless File.directory?("#{workspace_path}/#{name}")
    return false unless File.exists?("#{workspace_path}/#{name}/.mdi_cloud_agent_guid")
    return false unless File.exists?("#{workspace_path}/#{name}/initial.rb")
    return true
  end

  def get_agent_Gemfile_content(name)
    return "" unless File.exists?("#{workspace_path}/#{name}/Gemfile")
    File.read("#{workspace_path}/#{name}/Gemfile")
  end

  def get_agent_whenever_content(name)
    return "" unless File.exists?("#{workspace_path}/#{name}/config/schedule.rb")
    content = ''
    #content += "cron_tasks_folder=\'#{workspace_path}/#{name}/cron_tasks\'\n"
    content += "job_type :execute_order, \'curl -i -H \"Accept: application/json\" -H \"Content-type: application/json\" -X POST -d \\\'{\"agent\":\"#{name}\", \"order\":\":task\", \"params\":\":params\"}\\\' http://localhost:5001/remote_call\'\n"
    #content += "job_type :rake, echo :task\n"
    #content += "job_type :runner, echo :task\n"
    #content += "job_type :command, echo :task\n"

    content += File.read("#{workspace_path}/#{name}/config/schedule.rb")
  end

  def get_agents_cron_tasks(running_agents)
    @agents_cron_tasks ||= begin
      # init map
      final_map = {}
      running_agents.each { |agent|
        final_map[agent] = []
      }
      # run whenever
      `bundle exec whenever > /tmp/whenever_cron`
      cron_content = File.read('/tmp/whenever_cron')

      # let's parse the cron_content to find cron commands for each running agent
      cron_content.each_line { |line|
        #puts "get_agents_cron_tasks line: #{line}"
        if line.include?('/bin/bash -l -c \'curl')
          assigned_agent = ""
          running_agents.each { |agent|
            if line.include?(agent)
              assigned_agent = agent
            end
          }
          next unless assigned_agent != ""
          begin
            #extract {}
            in_par_cmd = line.split('{').second.split('}').first
            #puts "found #{in_par_cmd}"
            final_map[assigned_agent] << "{#{in_par_cmd}}"
          rescue Exception => e
            puts "get_agents_cron_tasks error on line #{line} :\n #{e}"
          end
        end
      }
      puts "get_agents_cron_tasks gives:\n#{final_map}"
      p 'get_agents_cron_tasks done'
    rescue => e
      p 'get_agents_cron_tasks fail'
      print_ruby_exception(e)
    end

    final_map
  end

  def set_run_agents(agents)
    FileUtils.touch("#{source_path}/.agents_to_run")
    File.open("#{source_path}/.agents_to_run", 'w') { |file| file.write(agents.join(';')) }
  end

  def remove_unvalid_agents(array)
    out = []
    array.each do |a|
      if is_agent_valid(a)
        out << a
      else
        p "Agent #{a} is not valid"
      end
    end
    out
  end

  def get_guid_from_name(name)
    return "" unless File.exists?("#{workspace_path}/#{name}/.mdi_cloud_agent_guid")
    File.read("#{workspace_path}/#{name}/.mdi_cloud_agent_guid")
  end

  def match_and_replace_in_folder(path, pattern, replace)
    get_files(path).each do |file_name|
      file_full = "#{path}/#{file_name}"
      puts "match_and_replace in file #{file_full}"
      text = File.read(file_full)
      File.open(file_full, 'w') { |file| file.write(text.gsub(pattern, replace)) }
    end
    get_dirs(path).each do |dir|
      match_and_replace_in_folder("#{path}/#{dir}", pattern, replace)
    end
  end

  #########################################################################################################


end

GEN = AgentsGenerator

