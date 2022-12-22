rednet.open("left")
term.clear()
term.setCursorPos(1,1)

local collection_queue = {}

--Listens for calls and sends it to the other endpoint
--Runs follow_up_queue to check for multiple riders and will
--add them to the queue table
function listen_for_call()
	while true do
		id, send_to, protocol = rednet.receive()
		print("System #" .. id .. " sent a cart to System #" .. send_to)
		rednet.send(tonumber(send_to), id, protocol)
		print("Sending a signal to System #" .. tonumber(send_to))
		follow_up_queue()
	end
end

--Waits for rednet receive packet, 19 seconds as it takes max 19 seconds
--for cart to reach top or bottom
--If 19 seconds pass and no packet, it will timeout and listening function resets
--If a packet is sent within that time, the repeater will add it to a queue with the
--time different, and continue to listen for 19 seconds until an iteration with no
--packet is sent
function follow_up_queue()
	while true do
		local crnt_time = os.time()
		id, send_to, protocol = rednet.receive(19)
		if id == nil then
			return
		else
			local time_diff = os.time() - crnt_time
			local time_diff = time_diff / .02
			local data = {id, send_to, protocol, time_diff}
			table.insert(collection_queue, data)
			print("Existing rider, adding new rider to queue...")
		end
	end
end

--Continuosly pops the first packet from the queue table
--If the packet exists, the repeater turtle will sleep for
--the difference between the duration of the packet receive
--and 19 seconds. This will allow for the other end point
--to successfully collect the cart in front.

--If a packet does not exist, means the table is empty and loop resets
function parse_queue_table()
	while true do
		local cart_data = table.remove(collection_queue)
		if cart_data ~= nil then
			os.sleep(19 - cart_data[4])
			rednet.send(tonumber(cart_data[2]), tostring(cart_data[1]), cart_data[3])
			print("Sending a signal to System #" .. tonumber(cart_data[2]))
		end
		--This is to queue and pull a fake event so the loop doesn't time out
		os.queueEvent("fakeEvent")
		os.pullEvent()
		print("queded")
	end
end


--Calls listen_for_call and parse_queue_table functions to run multi-thread
--One function continously listens for calls from an endpoint, and the other
--checks the queue table to send queue packets to the other end.
function main()
	while true do
		parallel.waitForAny(listen_for_call, parse_queue_table)
	end
end

main()