#
# Cookbook Name:: ring-devops
# Recipe:: tag_instance
#
# Copyright 2017, ring.com
#
# All rights reserved - Do Not Redistribute
#
# Loop over a hash and tags the instance with all of them
# Make sure the IAM instance role has the proper permissions

if (node.attribute?("ec2"))
  currentname = `aws ec2 describe-tags --filters "Name=resource-id,Values=#{node[:opsworks][:instance][:aws_instance_id]}" "Name=key,Values=Name" --region #{node[:opsworks][:instance][:region]} --output=text|cut -f5`

  if currentname.strip.empty? 
    Tag = `aws ec2 describe-tags --filters "Name=resource-id,Values=#{node[:opsworks][:instance][:aws_instance_id]}" "Name=key,Values=opsworks:instance" --region #{node[:opsworks][:instance][:region]} --output=text|cut -f5`
    out = `aws ec2 create-tags --resources "#{node[:opsworks][:instance][:aws_instance_id]}" --tags "Key=Name,Value='#{Tag}'" --region #{node[:opsworks][:instance][:region]}`
    Chef::Log.info("Tagging instance ENV. Ran 'aws ec2 create-tags --resources \"#{node[:opsworks][:instance][:aws_instance_id]}\" --tags \"Key=Name,Value=#{Tag}\" --region #{node[:opsworks][:instance][:region]}'.")
  end

  node['devops']['tag_instance_with'].each do |key, value|

    existentTag = `aws ec2 describe-tags --filters "Name=resource-id,Values=#{node[:opsworks][:instance][:aws_instance_id]}" "Name=key,Values=#{key}" --region #{node[:opsworks][:instance][:region]} --output=text|cut -f5`

    if existentTag.empty?
      out = `aws ec2 create-tags --resources "#{node[:opsworks][:instance][:aws_instance_id]}" --tags "Key=#{key},Value='#{value}'" --region #{node[:opsworks][:instance][:region]}`
      Chef::Log.info("Tagging instance Name tag. Ran 'aws ec2 create-tags --resources \"#{node[:opsworks][:instance][:aws_instance_id]}\" --tags \"Key=#{key},Value=#{value}\" --region #{node[:opsworks][:instance][:region]}'.")
    end

  end
end
