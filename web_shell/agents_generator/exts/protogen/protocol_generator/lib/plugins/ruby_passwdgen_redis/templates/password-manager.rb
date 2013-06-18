require 'redis'
require 'redis-lock'
require 'json'
require 'securerandom'

module Protogen

# I used to think that we should use redis expiration date feature to drop cookies. However, it would imply that we store passwords in simple
# elements, and we'd have to search them using "keys pattern" command, which is not recommended on a production environment. Therefore, we
# shall implement our own expiration system.

class CookiePasswdMgr
  def self.init(redis)
    @@redis = redis
  end

  def self.purge_outdated_passwd(cookie_name)
    @@redis.zremrangebyscore(cookie_name, '-inf', Time.now.to_i)
  end

  def self.get_passwd(cookie_name, duration, max_passwds)
    passwds = @@redis.zrangebyscore(cookie_name, '-inf', '+inf', :withscores => true)
    if passwds.size == 0 || (Time.now.to_i - (passwds.last[1].to_i-duration)) > duration/max_passwds # the latest was created more than enough ago
      begin
        @@redis.lock("#{cookie_name}_lock", 60, 4)
        passwds = @@redis.zrangebyscore(cookie_name, '-inf', '+inf', :withscores => true)
        if passwds.size == 0 || (Time.now.to_i - (passwds.last[1].to_i-duration)) > duration/max_passwds # second check to be sure it was not overrided by another agent
          purge_outdated_passwd(cookie_name)
          new_password = SecureRandom.hex(16)
          @@redis.zadd(cookie_name, Time.now.to_i+duration, new_password)
          out = new_password
        else
          out = passwds.last[0]
        end
      ensure
        @@redis.unlock("#{cookie_name}_lock")
      end
    else # no need to touch passwd
      out = passwds.last[0]
    end
    out
  end

  def self.get_all_passwd(message_name)
    cookies = @@redis.hgetall('cookies')
    cookies.delete_if{|cookie_name,messages_concerned| JSON.load(messages_concerned).include?(message_name) == false}
    all_pass = cookies.map{|cookie_name,_ | @@redis.zrangebyscore(cookie_name, Time.now.to_i, '+inf')}.flatten
  end
end

end
