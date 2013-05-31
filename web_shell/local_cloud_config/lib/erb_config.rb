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


def is_reminder_hidden
  @reminder_hidden ||= begin
    if File.exist?('.reminder_hidden')
      File.read('.reminder_hidden')
    else
      set_reminder_hidden(false)
      'false'
    end
  end
end

def set_reminder_hidden(val)
  if (@previous_reminder_hidden != val)
    File.open('.reminder_hidden', 'w') { |file| file.write(val) }
    @previous_reminder_hidden = val
    @reminder_hidden = val
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

def is_cron_tasks_visible
  @cron_tasks_visible ||= begin
    if File.exist?('.cron_tasks_visible')
      File.read('.cron_tasks_visible')
    else
      set_show_more_stats(false)
      'false'
    end
  end
end

def set_cron_tasks_visible(val)
  if (@previous_cron_tasks_visible != val)
    File.open('.cron_tasks_visible', 'w') { |file| file.write(val) }
    @previous_cron_tasks_visible = val
    @cron_tasks_visible = val
  end
end

