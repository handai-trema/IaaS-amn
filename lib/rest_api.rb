# -*- coding: utf-8 -*-
require 'grape'
require 'port'
require 'slice_exceptions'
require 'slice_extensions'
require 'trema'

module DRb
  # delegates to_json to remote object
  class DRbObject
    def to_json(*args)
      method_missing :to_json, *args
    end
  end
end

# Remote Slice class proxy
class Slice
  def self.method_missing(method, *args, &block)
    socket_dir = if FileTest.exists?('RoutingSwitch.ctl')
                   '.'
                 else
                   ENV['TREMA_SOCKET_DIR'] || Trema::DEFAULT_SOCKET_DIR
                 end
    remote_klass =
      Trema.trema_process('RoutingSwitch', socket_dir).controller.slice
    remote_klass.__send__(method, *args, &block)
  end
end

# REST API of Slice
# rubocop:disable ClassLength
class RestApi < Grape::API
  format :json

  helpers do
    def rest_api
      yield
    rescue Slice::NotFoundError => not_found_error
      error! not_found_error.message, 404
    rescue Slice::AlreadyExistsError => already_exists_error
      error! already_exists_error.message, 409
    end
  end

  desc 'Create Container.'
  params do
    requires :name, type: String, desc: 'Container_ name.'
    requires :user_name, type: String, desc: 'user_name.'
  end
  post '/api/create_container' do
    rest_api do
      puts "create container"
      name = params[:name]
      user_name = params[:user_name]
      puts name
      puts user_name
      empty_flag = true
      empty_ip_num_now = 0
      ip_infs = []
      new_ip_infs = []
      File.open('./VM/empty_ip_num.txt','r') do |file|
        file.each_line do |empty_ip_num|
          if empty_ip_num.to_i < 1 then
            empty_flag = false
          end
          empty_ip_num_now = empty_ip_num
        end
      end
      if !empty_flag then
        return "ip_address_full"
      end
      File.open('./VM/ip_table.txt','r') do |file|
        file.each_line do |ip_info|
          ip_infs.push(ip_info)
        end
      end
      create_flag = false
      ip_infs.each do |ip_info|
        used_flag = ip_info.split(",")[1]
        ip_address = ip_info.split(",")[0]
        if used_flag == "f" and !create_flag then
          cmd = "docker run --name " + name + 
            " --net shared_nw --ip " + ip_address + " -dt iaasamn/sshubuntu:latest"
          used_flag = "t"
          create_flag = true
          new_ip_infs.push(ip_address + "," + used_flag + "," + name + "," + user_name)
          puts "command:"
          puts cmd
          `#{cmd}`
          cmd = "docker exec -it "+name+" ping -c 1 192.168.1.251"
          `#{cmd}`
        else
          new_ip_infs.push(ip_info)
        end
      end
      File.open('./VM/empty_ip_num.txt','w') do |file|
        file.puts((empty_ip_num_now.to_i - 1))
      end
      File.open('./VM/ip_table.txt','w') do |file|
        new_ip_infs.each do |ip_info|
          file.puts(ip_info)
        end
      end
    end
  end

  desc 'Show Container.'
  params do
    requires :user_name, type: String, desc: 'user_name.'
  end
  post '/api/show_container' do
    rest_api do
      puts "show container";
      user_name = params[:user_name]
      container_infs = []
      File.open('./VM/ip_table.txt','r') do |file|
        file.each_line do |container_info|
          container_ip = container_info.split(",")[0]
          used_flag = container_info.split(",")[1]
          if used_flag == "t" then
            container_name = container_info.split(",")[2]
            container_user_name = container_info.split(",")[3].chomp
            if container_user_name == user_name then
              container_infs.push(container_info)
            end
          end
        end
      end
      return container_infs;
    end
  end
end
# rubocop:enable ClassLength
