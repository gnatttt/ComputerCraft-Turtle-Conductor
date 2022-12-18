rednet.open("left")
receiverID = 21
send_to = "20"
function spit_out_cart()
	print("Waiting for signal...")
	os.pullEvent("redstone")
	cart_slot = cart_search()
	if cart_slot == 0 then
		rednet.send(receiverID, "ERROR")
		return
	else
		turtle.select(cart_slot)
		turtle.place()
		print("Waiting for signal to start ride")
		sleep(2)
		os.pullEvent("redstone")
		redstone.setOutput("front", true)
		sleep(.5)
		redstone.setOutput("front", false)
		sleep(1)
		rednet.send(receiverID, send_to)
	end
	return
end

function cart_search()
	for slot = 1, 16 do
		turtle.select(slot)
		local item = turtle.getItemDetail()
		if item ~= nil then
			if string.find(item.name, "cart") ~= nil then
				return slot
			end
		end
	end
	print("Out of minecarts...")
	return 0
end

function collect_cart()
	id, signal = rednet.receive()
	if signal == "ERROR" then
		return
	end
	print("System #" .. signal .. " sent a cart")
	success = turtle.attack()
	while not success do
		success = turtle.attack()
	end
	return
end

function main()
	while true do
		parallel.waitForAll(spit_out_cart, collect_cart)
	end
end

main()