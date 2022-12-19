rednet.open("left")
--ID of the repeater turtle
--Signals are sent to this turtle from each end turtle to be relayed
--to the other end.
repeater_id = 21
--ID of the turtle at the other end the repeater will send a signal to
send_to = "20"

--If available, places a minecart on the rail in front when a redstone signal is
--applied
--The second redstone pulse will cause turtle to apply a redstone pulse
--to the rail to send user on the way
--Turtle will send a signal to the turtle at the other end to be ready for incoming cart
function spit_out_cart()
	print("Waiting for signal...")
	os.pullEvent("redstone")
	
	if not ping() then
		return
	end

	cart_slot = cart_search()
	--if no carts in inventory
	if cart_slot == 0 then
		--Will place a sign saying no cart left
		print("Out of minecarts")
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
		--sends signal to repeater with msg that is the ID of turtle at other end
		rednet.send(repeater_id, send_to)
	end
	return
end

--Helper method that iterates through turtle's inventory to search for an available minecart
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
	return 0
end


function ping()
	rednet.send(repeater_id, "ping20")
	_, reply = rednet.receive()
	if reply == "no" then
		return false
	else
		return true
	end
end

--Waits for a rednet message from the other end and will collect cart when it arrives
function collect_cart()
	id, signal = rednet.receive()
	print("System #" .. signal .. " sent a cart")
	--Tries to collect(by attacking) something in front
	--Will hit players crossing by, but will only get cart first
	success = turtle.attack()
	while not success do
		success = turtle.attack()
	end
	return
end


function main()
	while true do
		--Uses multi-threading to run both functions at the same time
		--Restarts loop when one function returns
		--This will allow for turtle to soft reset as it will only allow one
		--use riding at one time
		--While this isn't as good as multiple riders, it helps with different riders
		--colliding going up and down at the same time
		parallel.waitForAny(spit_out_cart, collect_cart)
	end
end

main()