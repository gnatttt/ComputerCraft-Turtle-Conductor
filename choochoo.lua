rednet.open("left")
term.clear()
term.setCursorPos(1,1)

--ID of the repeater turtle
--Signals are sent to this turtle from each end turtle to be relayed
--to the other end.
repeater_id = 21
--ID of the turtle at the other end the repeater will send a signal to
send_to = "20"

--Flag keeping check of whether or not the railway is being used.
local occupied = false

--If available, places a minecart on the rail in front when a redstone signal is
--applied
--The second redstone pulse will cause turtle to apply a redstone pulse
--to the rail to send user on the way
--Turtle will send a signal to the turtle at the other end to be ready for incoming cart
function spit_out_cart()
	print("Waiting for signal...")
	os.pullEvent("redstone")

	--Checks if occupied, doesn't allow same turtle to be outputted twice
	if occupied then
		print("Railway occupied, please wait.")
		while occupied do
			sleep(1)
		end
	end

	--Pings other turtle to see if it is occupied
	if ping() then
		print("Railway occupied, please wait.")
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
		rednet.send(repeater_id, send_to, "collect")
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

--Sends a ping to the other system and receives one back to check whether or not it is occupied
function ping()
	print("Pinging other system...")
	rednet.send(repeater_id, send_to, "ping")
	_, send_to, reply = rednet.receive()
	if string.find(reply, "yes") ~= nil then
		return true
	else
		return false
	end
end

--Waits for a rednet message from the other end and will collect cart when it arrives
function collect_cart()
	id, sender_id, protocol = rednet.receive()
	while protocol ~= "collect" do
		id, sender_id, protocol = rednet.receive()
		if protocol == "collect" then
			print("System #" .. sender_id .. " sent a cart")
			occupied = true
			--Tries to collect(by attacking) something in front
			--Will hit players crossing by, but will only get cart first
			success = turtle.attack()
			while not success do
				success = turtle.attack()
			end
			print("Successfully collected cart from System #" .. sender_id)
			occupied = false
			return
		end
	end
end

--Third multi-thread function that listens for the ping to send back a signal of occupancy
function listen_for_ping()
	while true do
		_, sender_id, protocol = rednet.receive()
		if protocol == "ping" then
			if occupied then
				rednet.send(repeater_id, tonumber(sender_id), "pingyes")
			else
				rednet.send(repeater_id, tonumber(sender_id), "pingno")
			end
		end
	end
end

function main()
	while true do
		--Uses multi-threading to run both functions at the same time
		--Restarts loop when one function returns
		--This will allow for turtle to soft reset as it will only allow one
		--use riding at one time
		--While this isn't as good as multiple riders, it helps with different riders
		--colliding going up and down at the same time
		parallel.waitForAny(spit_out_cart, collect_cart, listen_for_ping)
	end
end

main()