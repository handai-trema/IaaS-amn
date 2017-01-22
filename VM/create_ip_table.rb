
File.open("ip_table.txt","w") do |file|
  base_addr = "192.168.1."
  for num in 10..199 do
    addr = base_addr + num.to_s + ",f"
    file.puts(addr)
  end
end
