rednet.open("left")

function main()
	while true do
		id, send_to = rednet.receive()
		print("System #" .. id .. " sent a cart to System #" .. send_to)
		rednet.send(tonumber(send_to), id)
		print("Sending a signal to System #" .. tonumber(send_to))
	end
end

main()