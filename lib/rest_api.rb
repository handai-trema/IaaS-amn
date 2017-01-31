# -*- coding: utf-8 -*-
require 'grape'
require 'port'
require 'slice_exceptions'
require 'slice_extensions'
require 'trema'
require 'net/http'
require 'uri'

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
    requiers :ip_addr, type: String, desc: 'container_ip_addr.'
    requires :user_ip_addr, type: String, desc: 'user_ip_addr.'
  end
  post '/api/create_container' do
    rest_api do
      puts "create container"
      name = params[:name]
      container_ip_addr = params[:ip_addr]
      user_ip_addr = params[:user_ip_addr]
      puts name
      puts container_ip_addr
      #docker run
      cmd = "docker run --name " + name + 
        " --net shared_nw --ip " + container_ip_addr + " -dt iaasamn/sshubuntu:latest"
      puts "command:"
      puts cmd
      `#{cmd}`
      #docker exec ping コンテナ作成元のユーザ端末にpingを送る
      cmd = "docker exec -it "+ name + " ping -c 1 " + user_ip_addr
      `#{cmd}`
    end
  end
end
# rubocop:enable ClassLength
