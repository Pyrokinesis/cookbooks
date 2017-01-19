#
# Cookbook Name:: ring-clients-api
# Recipe:: deploy
#
# Copyright 2016, ring.com
#
# All rights reserved - Do Not Redistribute
#

env_srv1 = node['clients-api']['environments']['tier1']['env_srv']
Chef::Log.info("We got value for Env var #{env_srv1} - PABLO") 
env_db1 = node['clients-api']['environments']['tier1']['env_db']
env_user1 = node['clients-api']['environments']['tier1']['env_user']
env_pass1 = node['clients-api']['environments']['tier1']['env_pass']
env_file = node['clients-api']['environments']['files']['env_file']
Chef::Log.info("We got value for Env File #{env_file} - PABLO") 
env_srv2 = node['clients-api']['environments']['tier2']['env_srv']
env_db2 = node['clients-api']['environments']['tier2']['env_db']
env_user2 = node['clients-api']['environments']['tier2']['env_user']
env_pass2 = node['clients-api']['environments']['tier2']['env_pass']

environmentTag = `aws ec2 describe-tags --filters "Name=resource-id,Values=#{node[:opsworks][:instance][:aws_instance_id]}" --region #{node[:opsworks][:instance][:region]} --output=text | grep 'Env' | cut -f5`

def format_output(output)
  rows_array = output.split("\n").map { |line| line.split("\t") }
  rows_array.shift
  rows_array.each_with_object({}) { |(k,v), res| res[k] = v }
end
Chef::Log.info("Environment TAG is: #{environmentTag} - PABLO")

case environmentTag
    when 'beta', 'alpha'
      #dump firts mysql enviroment
      first_output = `mysql -h #{env_srv1} -u#{env_user1} -p#{env_pass1} -e 'SELECT name,value FROM env_variables' #{env_db1}`
      Chef::Log.info("We got mysql dump #{first_output} - PABLO")
      first_envs = format_output(first_output)
      Chef::Log.info("We got mysql dump #{first_envs} - PABLO")
      # dump second mysql enviroment
      second_output = `mysql -h #{env_srv2} -u#{env_user2} -p#{env_pass2} -e 'SELECT name,value FROM env_variables' #{env_db2}`
      second_envs = format_output(second_output)

      # Second sql query must overwrites Prod vars, and add new ones
      final_envs = first_envs.merge(second_envs)
      Chef::Log.info("We got FINAL merge #{final_envs} - PABLO")
      
      #Generate file
      env_file = open(env_file, "w")
      final_envs.each { |key, value| env_file.puts("#{key}=#{value}") }
      env_file.close
      
    when 'production', 'staging'
      #We create file with query output without doing merge
      sql_output = `mysql -h #{env_srv3} -u#{env_user3} -p#{env_pass3} -e 'SELECT name,value FROM env_variables' #{env_db3}`
      final_envs = format_output(sql_output)
      
      #Print sql query
      env_file = open(env_file, "w")
      final_envs.each { |key, value| env_file.puts("#{key}=#{value}") }
      env_file.close

end
