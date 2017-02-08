require 'json'

module View
  # Topology controller's GUI (vis).
  class VisJs
    def initialize(output = './tmp/topology.json')
      @output = output
    end

    # rubocop:disable AbcSize
    def update(_event, _changed, topology)
      nodes = topology.switches.each_with_object({}) do |each, tmp|
        tmp[each] = { "id"=> each, "label"=> each.to_hex }
      end
      i = 0
      links = topology.links.each_with_object({}) do |each, tmp|
        next unless nodes[each.dpid_a] && nodes[each.dpid_b]
        tmp[i] = { "id"=> 10000+i, "from"=> each.dpid_a, "to"=> each.dpid_b }
        i += 1
      end
      i = 0
      hosts = topology.hosts.each_with_object({}) do |each, tmp|
        ip_addr = each[1].to_s.split(".")[3].to_i
        if (ip_addr >= 248 && ip_addr <= 250) || ip_addr == 252 || ip_addr == 253 || ip_addr == 3 || ip_addr == 5 then
          next
        end
        tmp[i] = { "id"=> 100+i, "label"=> ("ip: " + each[1].to_s + " mac: " + each[0].to_s)}
        i += 1
      end
      i = 0
      h_links = topology.hosts.each_with_object({}) do |each, tmp|
#        tmp[nodes.length+i] = { "from"=> each[2], "to"=> nodes.length+i+2 }
         tmp[nodes.length+i] = { "id"=> 10000+nodes.length+i, "from"=> each[2], "to"=> 100+i }
        i += 1
      end
      open(@output, "w") do |io|
        JSON.dump([ "nodes"=> nodes.values, "hosts"=> hosts.values, "links"=> links.merge(h_links).values, "paths"=>topology.paths, "slices"=>topology.slices], io)
      end
    end
    # rubocop:enable AbcSize
#slices
    def to_s
      "vizJs mode, output = #{@output}"
    end
  end
end
