# -*- coding: utf-8 -*-
$:.unshift File.dirname(__FILE__)
$LOAD_PATH.unshift File.join(__dir__, '../vendor/topology/lib')

require 'active_support/core_ext/module/delegation'
require 'optparse'
require 'path_in_slice_manager'
require 'path_manager'
require 'topology_controller'
require 'arp_table'

# L2 routing switch
class RoutingSwitch < Trema::Controller
  # Command-line options of RoutingSwitch
  class Options
    attr_reader :slicing

    def initialize(args)
      @opts = OptionParser.new
      @opts.on('-s', '--slicing') { @slicing = true }
      @opts.parse [__FILE__] + args
    end
  end

  timer_event :flood_lldp_frames, interval: 1.sec

  delegate :flood_lldp_frames, to: :@topology

  def slice
    fail 'Slicing is disabled.' unless @options.slicing
    Slice
  end

  def update_slice
#ここでトポロジに追加する
    @topology.update_slice(Slice.all)
  end

  def start(args)
    @options = Options.new(args)
    @path_manager = start_path_manager
    @topology = start_topology
    @path_manager.add_observer @topology
    #Arpテーブル
    @arp_table = ArpTable.new
    #VMMangerの情報
    @VM_mac = []
    @VM_port = []
    @mac_slice = {}
    Slice.create("slice1")
    Slice.create("slice2")
    logger.info 'Routing Switch started.'
    logger.info 'routing switch'
  end

  delegate :switch_ready, to: :@topology
  delegate :features_reply, to: :@topology
  delegate :switch_disconnected, to: :@topology
  delegate :port_modify, to: :@topology

  def packet_in(dpid, packet_in)
    if (packet_in.ether_type.to_hex.to_s == "0x806" && packet_in.sender_protocol_address.to_s == "0.0.0.0") ||
        (packet_in.ether_type.to_hex.to_s == "0x800" && packet_in.source_ip_address.to_s == "0.0.0.0") then
      return ;
    end
    
    if packet_in.lldp? || packet_in.ether_type.to_hex.to_s == "0x806" || 
        (packet_in.ether_type.to_hex.to_s == "0x800" && packet_in.source_ip_address.to_s != "0.0.0.0") then
       @topology.packet_in(dpid, packet_in)
    end
    if packet_in.ether_type.to_hex.to_s == "0x806" || 
        packet_in.ether_type.to_hex.to_s == "0x800" && packet_in.source_ip_address.to_s != "0.0.0.0" then
      @path_manager.packet_in(dpid, packet_in)
      #end
    end
    #if (packet_in.ether_type.to_hex.to_s == "0x800" && packet_in.source_ip_address.to_s != "0.0.0.0") then
    #  packet_in_add_host_to_slice dpid, packet_in.in_port, packet_in.data
    #end
    #Arp解決
    case packet_in.data
    when Arp::Request
      packet_in_add_host_to_slice dpid, packet_in.in_port, packet_in.data
      packet_in_arp_request dpid, packet_in.in_port, packet_in.data
    when Arp::Reply
      packet_in_arp_reply dpid, packet_in
    end
  end

  def packet_in_arp_request(dpid, in_port, packet_in)
    puts "arp_request"
    #Arpリクエスト元の情報をarpテーブルに登録
    @arp_table.update(in_port,
                      packet_in.sender_protocol_address,
                      packet_in.source_mac)
    #宛先ホストのmacアドレスをarpテーブルから探す
    if @arp_table.lookup(packet_in.target_protocol_address)
      dest_host_mac_address = @arp_table.lookup(packet_in.target_protocol_address).mac_address
      print "dest_host_mac_addr: "
      puts dest_host_mac_address
      print "packet_in.mac_addr: "
      puts packet_in.source_mac
      if @mac_slice.has_key?(dest_host_mac_address) then
        if @mac_slice.has_key?(packet_in.source_mac) then
          @mac_slice[dest_host_mac_address].each do |mac_slice|
            @mac_slice[packet_in.source_mac].each do |mac_slice2|
              print "mac_slice:"
              puts mac_slice
              print "mac_slice2:"
              puts mac_slice2
              if mac_slice == mac_slice2 then
                puts "Reply!"
                send_packet_out(
                      dpid,
                      raw_data: Arp::Reply.new(destination_mac: packet_in.source_mac,
                                               source_mac: dest_host_mac_address,
                                               sender_protocol_address: packet_in.target_protocol_address,
                                               target_protocol_address: packet_in.sender_protocol_address
                                               ).to_binary,
                      actions: SendOutPort.new(in_port))
                return
              end
            end
          end
        end
      else
        send_packet_out(
                        dpid,
                        raw_data: Arp::Reply.new(destination_mac: packet_in.source_mac,
                                                 source_mac: dest_host_mac_address,
                                                 sender_protocol_address: packet_in.target_protocol_address,
                                                 target_protocol_address: packet_in.sender_protocol_address
                                                 ).to_binary,
                        actions: SendOutPort.new(in_port))
      end
    end
  end

  def packet_in_arp_reply(dpid, packet_in)
    @arp_table.update(packet_in.in_port,
                      packet_in.sender_protocol_address,
                      packet_in.source_mac)
  end

  #スライスへのホストの追加
  def packet_in_add_host_to_slice(dpid, in_port, packet_in)
    user_addr_end = packet_in.sender_protocol_address.to_s.split(".")[3].to_i
    puts "slice_add_to_host: "
    print "ip: " 
    puts user_addr_end
    print "port: "
    puts dpid.to_hex.to_s + ":" + in_port.to_s
    #コントローラ - 管理端末とVMManagerのスライス
    if user_addr_end == 251 then
      puts "add_251_slice1 2:"
      Slice.find_by!(name: "slice1").
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
      Slice.find_by!(name: "slice2").
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
      @mac_slice[packet_in.source_mac] = ["slice1","slice2"]
    #コントローラ端末内WEBサーバ - 管理端末のスライス
    elsif user_addr_end >= 7 && user_addr_end <= 9 then
      puts "add_4_slice1:"
      Slice.find_by!(name: "slice1").
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
      @mac_slice[packet_in.source_mac] = ["slice1"]
    #コントローラ端末内RESTAPIサーバ - VMManagerのスライス
    elsif user_addr_end >= 2 && user_addr_end <= 6  then
      puts "add_2_slice2:"
      result = Slice.find_by!(name: "slice2").add_mac_address(packet_in.source_mac, 
                                                              Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
      if result == "success" then
        @VM_mac.push(packet_in.source_mac)
        @VM_port.push(dpid.to_hex.to_s + ":" + in_port.to_s)
        puts "VM_mac:"
        p @VM_mac
        puts "VM_port:"
        p @VM_port
        @mac_slice[packet_in.source_mac] = ["slice2"]
      end
    #ユーザ端末 - VMManagerのスライス
    elsif user_addr_end >= 200 && user_addr_end <= 231 then
      puts "add_user_slice" + user_addr_end.to_s
      slice_name = "slice" + user_addr_end.to_s
      Slice.create(slice_name)
      Slice.find_by!(name: slice_name).
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
      @VM_mac.each_with_index do |mac_addr, index|
        port_info = @VM_port[index]
        Slice.find_by!(name: slice_name).
        add_mac_address(mac_addr, Port.parse(port_info))
        @mac_slice[mac_addr] = [slice_name]
      end
      @mac_slice[packet_in.source_mac] = [slice_name]
     #ユーザ端末 - コンテナ - VMManagerのスライス
    elsif user_addr_end >= 10 && user_addr_end <= 199 then
      puts "target: " + packet_in.target_protocol_address.to_s.split(".")[3]
      target_ip = packet_in.target_protocol_address.to_s.split(".")[3].to_i
      if target_ip == 3 || target_ip == 5 || (target_ip >= 10 && target_ip <= 199) then
        return ;
      end
      puts "add_user_slice" + user_addr_end.to_s
      slice_name = "slice" + packet_in.target_protocol_address.to_s.split(".")[3]
      Slice.find_by!(name: slice_name).
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
      @mac_slice[packet_in.source_mac] = [slice_name]
    end
    update_slice
    puts "slice state:"
    p @mac_slice
  end

  private

  def start_path_manager
    fail unless @options
    (@options.slicing ? PathInSliceManager : PathManager).new.tap(&:start)
  end

  def start_topology
    fail unless @path_manager
    TopologyController.new { |topo| topo.add_observer @path_manager }.start
  end
end
