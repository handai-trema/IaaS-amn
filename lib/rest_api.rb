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
    requires :con_num, type: Integer, desc: 'Container_num.'
  end
  post '/api/create/:name/:con_num' do
    rest_api do
      print "create container";
      name = params[:name]
      num = params[:com_num]
      cnt = 0
      empty_flag = true
      ip_infs = []
      new_ip_infs = []
      File.open('./VM/empty_ip_num.txt','r') do |file|
        file.each_line do |empty_ip_num|
          if empty_ip_num.to_i < num.to_i then
            empty_flag = false
          end
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
      ip_infs.each do |ip_info|
        used_flag = ip_info.split(",")[1]
        ip_address = ip_info.split(",")[0]
        if used_flag == "f" and cnt < num then
          cmd = "docker run --name" + name + cnt.to_s + 
            " --net shared_nw --ip" + ip_address + "-dt iaasamn/sshubuntu:latest"
          used_flag = "t"
          cnt = cnt + 1
        end
        new_ip_infs.push(ip_address + "," + used_flag)
      end
      File.open('./VM/empty_ip_num.txt','w') do |file|
        file.puts((empty_ip_num.to_i + num.to_i))
      end
      File.open('./VM/ip_table.txt','w') do |file|
        new_ip_infs.each do |ip_info|
          file.puts(ip_info)
        end
      end
    end
  end
end
# rubocop:enable ClassLength
