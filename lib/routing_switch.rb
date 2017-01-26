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
    @VM_mac = ""
    @VM_port = ""
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
    if packet_in.lldp? || packet_in.ether_type.to_hex.to_s == "0x806" || 
        (packet_in.ether_type.to_hex.to_s == "0x800" && packet_in.source_ip_address.to_s != "0.0.0.0") then
       @topology.packet_in(dpid, packet_in)
    end
    if packet_in.ether_type.to_hex.to_s == "0x800" && packet_in.source_ip_address.to_s != "0.0.0.0" then
      #if packet_in.source_mac != packet_in.destination_mac then
      puts @path_manager
      @path_manager.packet_in(dpid, packet_in)
      #end
    end
    #if (packet_in.ether_type.to_hex.to_s == "0x800" && packet_in.source_ip_address.to_s != "0.0.0.0") then
    #  packet_in_add_host_to_slice dpid, packet_in.in_port, packet_in.data
    #end
    #Arp解決
    case packet_in.data
    when Arp::Request
      packet_in_arp_request dpid, packet_in.in_port, packet_in.data
      packet_in_add_host_to_slice dpid, packet_in.in_port, packet_in.data
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

  def packet_in_arp_reply(dpid, packet_in)
    @arp_table.update(packet_in.in_port,
                      packet_in.sender_protocol_address,
                      packet_in.source_mac)
  end

  #スライスへのホストの追加
  def packet_in_add_host_to_slice(dpid, in_port, packet_in)
    user_addr_end = packet_in.source_ip_address.to_s.split(".")[3].to_i
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
    #コントローラ端末内WEBサーバ - 管理端末のスライス
    elsif user_addr_end >= 4 && user_addr_end <= 9 then
      puts "add_4_slice1:"
      Slice.find_by!(name: "slice1").
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
    #コントローラ端末内RESTAPIサーバ - VMManagerのスライス
    elsif user_addr_end == 2 then
      puts "add_2_slice2:"
      Slice.find_by!(name: "slice2").
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
      @VM_mac = packet_in.source_mac
      @VM_port = dpid.to_hex.to_s + ":" + in_port.to_s
    #ユーザ端末 - VMManagerのスライス
    elsif user_addr_end >= 200 && user_addr_end <= 231 then
      puts "add_user_slice" + user_addr_end.to_s
      slice_name = "slice" + user_addr_end.to_s
      Slice.create(slice_name)
      Slice.find_by!(name: slice_name).
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
      Slice.find_by!(name: slice_name).
        add_mac_address(@VM_mac, Port.parse(@VM_port))
     #ユーザ端末 - コンテナ - VMManagerのスライス
    elsif user_addr_end >= 10 && user_addr_end <= 199 then
      puts "add_user_slice" + user_addr_end.to_s
      slice_name = "slice" + ??
      Slice.find_by!(name: slice_name).
        add_mac_address(packet_in.source_mac, Port.parse(dpid.to_hex.to_s + ":" + in_port.to_s))
    end

    update_slice
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
