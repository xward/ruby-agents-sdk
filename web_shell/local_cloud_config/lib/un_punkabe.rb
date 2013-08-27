#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

module PUNK

  #============================== CLASSES ========================================

  class PunkEvent < Struct.new(:type, :way, :title, :start_time, :end_time, :elaspe_time, :content)
  end

  class PunkPendingStack < Struct.new(:id, :lines, :action)
  end



  #============================== METHODS ========================================


  def self.un_punk(txt_src)
    punk_events = []

    punks_pending = []

    txt_src.each_line{ |line|
      tak = line.index('PUNKabeNK_') # start
      if tak != nil
        puts "trig #{line}"
        p ''
        # get id
        id = line.split('_')[1]
        id.delete!("\n")
        action = line.split('_')[2]

        puts "NEW ID '#{id}' with action '#{action}'"
        p ''

        # create new pending stack
        punks_pending << PunkPendingStack.new(id, [], action)
        next
      end
      tak = line.index('PUNKabeDROP_') # break
      if tak != nil
        id = line.split('_')[1]
        id.delete!("\n")

        puts "drop #{id}"
        # search if stack contain
        punks_pending.each { |pending|
          if pending['id'] == id
                    puts "dropping! #{id} #{punks_pending.size} pending left"

            punks_pending.delete_at(punks_pending.index(pending))
          end
        }
        next
      end

      tak = line.index('PUNKabe_') # end
      if tak != nil
        puts "trig #{line}"
        p ''
        # get id
        params = line.split('PUNKabe_')[1]
        id = params.split('_axd_').first
        rjson = params.split('_axd_')[1]

        puts "END ID '#{id}' with raw json = #{rjson}"
        p ''

        json = JSON.parse(rjson)
        puts "json = #{json}"
        p ''

        # search if stack contain
        punks_pending.each { |pending|
          if pending['id'] == id
            puts "found #{id} in pending with #{pending.lines.size} lines !  #{punks_pending.size} pending left"

            punk_events << PunkEvent.new(json['type'], json['way'], json['title'], line[15..22], '', '', pending.lines)
            punks_pending.delete_at(punks_pending.index(pending))
            break
          end
        }
        next
      end

      # fill all pending with current line
      punks_pending.each { |pending|
        begin
        line.delete!("\n")
        rescue Exception => e
          # utf8 errors
          puts "error on line.delete #{e.inspect}"
        end

        if line != ''
          pending.lines << line
        end
      }
    }

    # seek in an action is in progress
    pend = punks_pending.first
    if pend == nil
      $pending_action = nil
    else
      $pending_action = pend.action
      puts "pending_action loading with #{pend.inspect} (#{punks_pending.size} pending)"
    end


    #puts "Reconstruct successful with :"
    #p punk_events

    punk_events
  end


  def self.title_to_html(title)
    title.gsub!('->','<i class="icon-arrow-right icon-white"></i>')
    title.gsub!('<-','<i class="icon-arrow-left icon-white"></i>')

    title.gsub!('SERVER','<i class="icon-th icon-white"></i>')

    title.gsub!('PRESENCE','<i class="icon-star icon-white"></i>')
    title.gsub!('MSG','<i class="icon-envelope icon-white"></i>')
    title.gsub!('TRACK','<i class="icon-th-list icon-white"></i>')
    title.gsub!('ORDER','<i class="icon-fire icon-white"></i>')

    title.gsub!('ACK','<i class="icon-share icon-white"></i>')

    agent_pos = title.index('AGENT')
    agent_end_pos = title.index('TNEGA')
    if agent_pos != nil && agent_end_pos != nil
      agent_name = title[(agent_pos+6)..(agent_end_pos-1)]

      title.gsub!(title[agent_pos..(agent_end_pos+4)], "<span class=\"label label-warning\">#{agent_name}</span>")

      #title.gsub!(title[agent_pos..(agent_end_pos+4)], "[<i class=\"icon-th-large icon-white\"></i> #{agent_name}]")

    end

    title
  end


  def self.gen_server_crash_title()
    `cd ../local_cloud; ./local_cloud.sh is_running`
    if File.exist?('/tmp/mdi_server_run_id')
      used_server_run_id =  File.read('/tmp/mdi_server_run_id')
    else
      used_server_run_id = nil
    end
    if File.exist?('/tmp/local_cloud_running')
      server_running =  File.read('/tmp/local_cloud_running')
    else
      server_running = nil
    end

    p "server_run_id = '#{$server_run_id}'' and used_server_run_id = '#{used_server_run_id}'"

    if "#{$server_run_id}" == "#{used_server_run_id}" && server_running == 'no'
      p "SERVER is broken"
      title_to_html("SERVER master crash fail")
    else
      p "SERVER is alive"
      ''
    end
  end

  def self.is_ruby_server_running()
    `cd ../local_cloud; ./local_cloud.sh is_running`
    false
    if File.exist?('/tmp/local_cloud_running')
      server_running =  File.read('/tmp/local_cloud_running')
      true if server_running == 'yes'
    end
  end

  def self.gen_loading_action()
    $pending_action
  end

end
