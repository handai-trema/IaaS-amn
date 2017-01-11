$LOAD_PATH.unshift File.join(__dir__, '../vendor/topology/lib')

require 'active_support/core_ext/module/delegation'
require 'optparse'
require 'path_manager'
require 'path_in_slice_manager'
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
    logger.info 'Routing Switch started.'
  end

  delegate :switch_ready, to: :@topology
  delegate :features_reply, to: :@topology
  delegate :switch_disconnected, to: :@topology
  delegate :port_modify, to: :@topology

  def packet_in(dpid, packet_in)
    @topology.packet_in(dpid, packet_in) if packet_in.lldp? ||
      packet_in.ether_type == "0x0806" || (packet_in.ether_type == "0x0800" && packet_in.source_ip_address.to_s != "0.0.0.0")
    @path_manager.packet_in(dpid, packet_in) unless packet_in.lldp?
    #Arp解決
    case packet_in.data
    when Arp::Request
      packet_in_arp_request dpid, packet_in.in_port, packet_in.data
    when Arp::Reply
      packet_in_arp_reply dpid, packet_in
    end
  end

  def packet_in_arp_request(dpid, in_port, packet_in)
    #Arpリクエスト元の情報をarpテーブルに登録
    @arp_table.update(packet_in.in_port,
                      packet_in.sender_protocol_address,
                      packet_in.source_mac)
    #宛先ホストのmacアドレスをarpテーブルから探す
    arp_request = packet_in.data
    if lookup(packet_in.sender_protocol_address)
      dest_host_mac_address = lookup(packet_in.sender_protocol_address)
      send_packet_out(
                      dpid,
                      raw_data: Arp::Reply.new(destination_mac: arp_request.source_mac,
                                               source_mac: dest_host_mac_address,
                                               sender_protocol_address: arp_request.target_protocol_address,
                                               target_protocol_address: arp_request.sender_protocol_address
                                               ).to_binary,
                      actions: SendOutPort.new(in_port))
    end
  end

  def packet_in_arp_reply(dpid, packet_in)
    @arp_table.update(packet_in.in_port,
                      packet_in.sender_protocol_address,
                      packet_in.source_mac)
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
