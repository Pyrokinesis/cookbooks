#
# Cookbook Name:: ring-clients-api
# Recipe:: deploy
#
# Copyright 2016, ring.com
#
# All rights reserved - Do Not Redistribute
#
# USAGE:
# 
# 
# 

# Define needed variables for script.
maindb_srv = node['clients-api']['env-vars']['maindb']['srv']
maindb_db = node['clients-api']['env-vars']['maindb']['db']
maindb_user = node['clients-api']['env-vars']['maindb']['user']
maindb_pass = node['clients-api']['env-vars']['maindb']['pass']

secdb_srv = node['clients-api']['env-vars']['secdb']['srv']
secdb_db = node['clients-api']['env-vars']['secdb']['db']
secdb_user = node['clients-api']['env-vars']['secdb']['user']
secdb_pass = node['clients-api']['env-vars']['secdb']['pass']

env_file = node['clients-api']['env-vars']['output']['file']

# Query AWS EC2 Intance/Node running recipe to get Environment Tag of it. 
begin
  ec2_tag = `aws ec2 describe-tags --filters "Name=resource-id,Values=#{node[:opsworks][:instance][:aws_instance_id]}" --region #{node[:opsworks][:instance][:region]} --output=text | grep 'Env' | cut -f5`
  Chef::Log.info("Successfully retrieved enviroment tag #{ec2_tag.chomp}")
  ec2_tag = ec2_tag.chomp
rescue
  Chef::Log.fatal("Could not retrieve EC2 environment tag for this node")
  raise
end

ruby_block 'Execute MySQL dump and merge variables with Ruby' do
  block do
    
    
    case ec2_tag
    when 'beta', 'alpha'
        # Query and dump main DB to get Production or Staging variables
        first_output = `mysql -h #{maindb_srv} -u#{maindb_user} -p#{maindb_pass} -e 'SELECT name,value FROM env_variables' #{maindb_db}`
        Chef::Log.info("Successfully connected and dumped MySQL server #{maindb_srv} database #{maindb_db}")
        rows_array1 = first_output.split("\n").map { |line| line.split("\t") }
        rows_array1.shift
        first_envs = rows_array1.each_with_object({}) { |(k,v), res| res[k] = v }
      
        # Query and dump secondary DB to get Beta or Alpha variables
        second_output = `mysql -h #{secdb_srv} -u#{secdb_user} -p#{secdb_pass} -e 'SELECT name,value FROM env_variables' #{secdb_db}`
        Chef::Log.info("Successfully connected and dumped MySQL server #{secdb_srv} database #{secdb_db}")
        rows_array2 = second_output.split("\n").map { |line| line.split("\t") }
        rows_array2.shift
        second_envs = rows_array2.each_with_object({}) { |(k,v), res| res[k] = v }
                
        # Merge both dumps to array. Alpha or Beta takes precedence over Staging or Prodcution.
        final_envs = first_envs.merge(second_envs)
        # Write array to file
        env_file = open(env_file, "w")
        final_envs.each { |key, value| env_file.puts("#{key}=#{value}") }
        env_file.close
        Chef::Log.info("Merged Array successfully writed to file #{env_file}")

    when 'production', 'staging'
        # If node is tagged Production or Staging no need to merge environment variables
        sql_output = `mysql -h #{maindb_srv} -u#{maindb_user} -p#{maindb_pass} -e 'SELECT name,value FROM env_variables' #{maindb_db}`
        Chef::Log.info("Successfully connected and dumped MySQL server #{maindb_srv} database #{maindb_db}")
        rows_array3 = sql_output.split("\n").map { |line| line.split("\t") }
        rows_array3.shift
        final_envs = rows_array3.each_with_object({}) { |(k,v), res| res[k] = v }

        # Write array to file
        env_file = open(env_file, "w")
        final_envs.each { |key, value| env_file.puts("#{key}=#{value}") }
        env_file.close
        Chef::Log.info("Array successfully writed to file #{env_file}")
    end
  end
  action :run
end
