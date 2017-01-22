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

  desc 'Creates a slice.'
  params do
    requires :name, type: String, desc: 'Slice ID.'
  end
  post :slices do
    rest_api { Slice.create params[:name] }
  end

  desc 'Deletes a slice.'
  params do
    requires :name, type: String, desc: 'Slice ID.'
  end
  delete :slices do
    rest_api { Slice.destroy params[:name] }
  end

  desc 'Lists slices.'
  get :slices do
    rest_api { Slice.all }
  end

  desc 'Shows a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
  end
  get 'slices/:slice_id' do
    rest_api { Slice.find_by!(name: params[:slice_id]) }
  end

##ginnan add start
  desc 'Merge slices.'
  params do
    requires :new_slice, type: String, desc: 'Slice ID.'
    requires :a_slice, type: String, desc: 'Slice ID.'
    requires :b_slice, type: String, desc: 'Slice ID.'
  end
  post 'slices/:new_slice' do
    rest_api do 
      DRb.start_service#
      Slice.create params[:new_slice]
      puts Slice.find_by!(name: params[:a_slice])
      puts "a", Slice.find_by!(name: params[:a_slice]).ports
      puts Slice.find_by!(name: params[:b_slice])
      puts "b", Slice.find_by!(name: params[:b_slice]).ports
      Slice.find_by!(name: params[:a_slice]).each do |port, mac_addresses|#
        Slice.find_by!(name: params[:new_slice]).add_port(port)
        mac_addresses.each do |mac|
          Slice.find_by!(name: params[:new_slice]).add_mac_address(mac, port)
        end
      end
      Slice.find_by!(name: params[:b_slice]).each do |port, mac_addresses|#
        Slice.find_by!(name: params[:new_slice]).add_port(port)
        mac_addresses.each do |mac|
          Slice.find_by!(name: params[:new_slice]).add_mac_address(mac, port)
        end
      end
      Slice.destroy params[:a_slice]
      Slice.destroy params[:b_slice]
    end
  end
#ginnnan add end

  desc 'Adds a port to a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :dpid, type: Integer, desc: 'Datapath ID.'
    requires :port_no, type: Integer, desc: 'Port number.'
  end
  post 'slices/:slice_id/ports' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        add_port(dpid: params[:dpid], port_no: params[:port_no])
    end
  end

  desc 'Deletes a port from a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :dpid, type: Integer, desc: 'Datapath ID.'
    requires :port_no, type: Integer, desc: 'Port number.'
  end
  delete 'slices/:slice_id/ports' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        delete_port(dpid: params[:dpid], port_no: params[:port_no])
    end
  end

  desc 'Lists ports.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
  end
  get 'slices/:slice_id/ports' do
    rest_api { Slice.find_by!(name: params[:slice_id]).ports }
  end

  desc 'Shows a port.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
  end
  get 'slices/:slice_id/ports/:port_id' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        find_port(Port.parse(params[:port_id]))
    end
  end

# tuikabysatake

  desc 'Show.'
  params do
  end
  post '/api/status/' do
    rest_api do
      print "tuikasatakeby works!";
      str =""
      File.open('./tmp/topology.json') do |file|
        # IO#each_lineは1行ずつ文字列として読み込み、それを引数にブロックを実行する
        # 第1引数: 行の区切り文字列
        # 第2引数: 最大の読み込みバイト数
        # 読み込み用にオープンされていない場合にIOError
        file.each_line do |labmen|
          # labmenには読み込んだ行が含まれる
          #  print labmen
          str += labmen
        end
      end
      return str
    end
  end


# tuikabysatake

  desc 'Adds a host to a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
    requires :name, type: String, desc: 'MAC address.'
  end
  post '/slices/:slice_id/ports/:port_id/mac_addresses' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        add_mac_address(params[:name], Port.parse(params[:port_id]))
    end
  end

  desc 'Deletes a host from a slice.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
    requires :name, type: String, desc: 'MAC address.'
  end
  delete '/slices/:slice_id/ports/:port_id/mac_addresses' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        delete_mac_address(params[:name], Port.parse(params[:port_id]))
    end
  end

  desc 'List MAC addresses.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
  end
  get 'slices/:slice_id/ports/:port_id/mac_addresses' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        mac_addresses(Port.parse(params[:port_id]))
    end
  end

  desc 'Shows a MAC address.'
  params do
    requires :slice_id, type: String, desc: 'Slice ID.'
    requires :port_id, type: String, desc: 'Port ID.'
    requires :mac_address_id, type: String, desc: 'MAC address.'
  end
  get 'slices/:slice_id/ports/:port_id/mac_addresses/:mac_address_id' do
    rest_api do
      Slice.find_by!(name: params[:slice_id]).
        find_mac_address(Port.parse(params[:port_id]), params[:mac_address_id])
    end
  end
end
# rubocop:enable ClassLength
