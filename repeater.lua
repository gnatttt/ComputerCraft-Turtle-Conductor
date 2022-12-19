rednet.open("left")
term.clear()
term.setCursorPos(1,1)


--Receives signals from one end and relays it to the other end
--This is essentially a repeater to extend signals
function main()
	while true do
		id, send_to, protocol = rednet.receive()
		print("System #" .. id .. " sent a cart to System #" .. send_to)
		rednet.send(tonumber(send_to), id, protocol)
		print("Sending a signal to System #" .. tonumber(send_to))
	end
end

main()