#########################################################
# Xavier Demompion : xavier.demompion@mobile-devices.fr
# Mobile Devices 2013
#########################################################

def is_reset_log_checked
  @reset_log_checked ||= begin
    if File.exist?('.reset_log_checked')
      File.read('.reset_log_checked')
    else
      set_reset_log_checked(true)
      'true'
    end
  end
end

def set_reset_log_checked(val)
  if (@previous_reset_log_checked != val)
    File.open('.reset_log_checked', 'w') { |file| file.write(val) }
    @previous_reset_log_checked = val
    @reset_log_checked = val
  end
end


def is_show_more_stats
  @show_more_stats ||= begin
    if File.exist?('.show_more_stats')
      File.read('.show_more_stats')
    else
      set_show_more_stats(false)
      'false'
    end
  end
end

def set_show_more_stats(val)
  if (@previous_show_more_stats != val)
    File.open('.show_more_stats', 'w') { |file| file.write(val) }
    @previous_show_more_stats = val
    @show_more_stats = val
  end
end


def is_log_show_com
  @log_show_com ||= begin
    if File.exist?('.log_show_com')
      File.read('.log_show_com')
    else
      set_log_show_com(true)
      'true'
    end
  end
end

def set_log_show_com(val)
  if (@previous_log_show_com != val)
    File.open('.log_show_com', 'w') { |file| file.write(val) }
    @previous_log_show_com = val
    @log_show_com = val
  end
end


def is_log_show_server
  @log_show_server ||= begin
    if File.exist?('.log_show_server')
      File.read('.log_show_server')
    else
      set_log_show_server(true)
      'true'
    end
  end
end

def set_log_show_server(val)
  if (@previous_log_show_server != val)
    File.open('.log_show_server', 'w') { |file| file.write(val) }
    @previous_log_show_server = val
    @log_show_server = val
  end
end



def is_log_show_process
  @log_show_process ||= begin
    if File.exist?('.log_show_process')
      File.read('.log_show_process')
    else
      set_log_show_process(true)
      'true'
    end
  end
end

def set_log_show_process(val)
  if (@previous_log_show_process != val)
    File.open('.log_show_process', 'w') { |file| file.write(val) }
    @previous_log_show_process = val
    @log_show_process = val
  end
end


def is_log_show_error
  @log_show_error ||= begin
    if File.exist?('.log_show_error')
      File.read('.log_show_error')
    else
      set_log_show_error(true)
      'true'
    end
  end
end

def set_log_show_error(val)
  if (@previous_log_show_error != val)
    File.open('.log_show_error', 'w') { |file| file.write(val) }
    @previous_log_show_error = val
    @log_show_error = val
  end
end
