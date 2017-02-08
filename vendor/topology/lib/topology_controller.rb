require 'command_line'
require 'topology'

# This controller collects network topology information using LLDP.
class TopologyController < Trema::Controller
  timer_event :flood_lldp_frames, interval: 1.sec

  attr_reader :topology

  def initialize(&block)
    super
    @command_line = CommandLine.new(logger)
    @topology = Topology.new
    block.call self
  end

  def start(args = [])
    @command_line.parse(args)
    @topology.add_observer @command_line.view
    logger.info "Topology started (#{@command_line.view})."
    self
  end

  def add_observer(observer)
    @topology.add_observer observer
  end

  def switch_ready(dpid)
    send_message dpid, Features::Request.new
  end

  def features_reply(dpid, features_reply)
    @topology.add_switch dpid, features_reply.physical_ports.select(&:up?)
  end

  def switch_disconnected(dpid)
    #@topology.delete_switch dpid
  end

  def port_modify(_dpid, port_status)
    updated_port = port_status.desc
    return if updated_port.local?
    if updated_port.down?
      @topology.delete_port updated_port
    elsif updated_port.up?
      @topology.add_port updated_port
    else
      fail 'Unknown port status.'
    end
  end

  def packet_in(dpid, packet_in)
    if packet_in.lldp?
      @topology.maybe_add_link Link.new(dpid, packet_in)
    else
      if packet_in.ether_type.to_hex.to_s == "0x806" then
        @topology.maybe_add_host(packet_in.source_mac, 
                                 packet_in.sender_protocol_address, 
                                 dpid, 
                                 packet_in.in_port)
      elsif packet_in.ether_type.to_hex.to_s == "0x800" then
        @topology.maybe_add_host(packet_in.source_mac, 
                                 packet_in.source_ip_address, 
                                 dpid, 
                                 packet_in.in_port)
      end 
    end
  end

  def flood_lldp_frames
    @topology.ports.each do |dpid, ports|
      send_lldp dpid, ports
      #ports.each do |port|
      #  send_message(dpid, PortStats::Request.new(port[:port_no]))
      #end
    end
  end

  def add_path(path)
    @topology.maybe_add_path(path)
  end

  def del_path(path)
    @topology.maybe_delete_path(path)
  end

  def update_slice(slice)
    @topology.maybe_update_slice(slice)
  end

  #def stats_reply(dpid, message)
  #  puts "[FlowDumper::stats_reply]"
  #  puts "stats of dpid:#{dpid}"
  #  puts "* transaction id: #{message.transaction_id}"
  #  puts "* flags: #{message.type}"
  #  puts "* type: #{message.type}"
  #  puts message.stats

   # if message.type == Trema::StatsReply::OFPST_PORT
   #   message.stats.each do |each|
   #     #puts each.[field]
   #     rx1 = each.rx_packets
   #     tx1 = each.tx_packets
   #     ts1 = time.now.to_i
   #     entry1 = [rx, tx, ts]
   #     unless stats.has_key?("#{dpid}")
   #       stats["#{dpid}"] = entry
   #     else
   #       entry0 = stats["#{dpid}"]
   #       rx0 = entry0[0]
   #       tx0 = entry0[1]
   #       ts0 = entry0[2]
   #       rx = rx1 - rx0
   #       tx = tx1 - tx0
   #       ti = ts1 - ts0
   #       rt_rate = rx / tx
   #       tx_speed = tx / ti
   #       if rt_rate < rt_rate_threshold && tx_speed < tx_speed_threshold
   #         # out!!
   #       end
   #     end
   #   end
   # end
  #end

  private

  def send_lldp(dpid, ports)
    ports.each do |each|
      port_number = each.number
      send_packet_out(
        dpid,
        actions: SendOutPort.new(port_number),
        raw_data: lldp_binary_string(dpid, port_number)
      )
    end
  end

  def lldp_binary_string(dpid, port_number)
    destination_mac = @command_line.destination_mac
    if destination_mac
      Pio::Lldp.new(dpid: dpid,
                    port_number: port_number,
                    destination_mac: destination_mac).to_binary
    else
      Pio::Lldp.new(dpid: dpid, port_number: port_number).to_binary
    end
  end
end
