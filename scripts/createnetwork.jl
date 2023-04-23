
#Reads the location file and returns the location coordinates
function readlocations(locationfilename, numlocs)

	data = CSV.read(locationfilename, DataFrame)
	
	loccoords = hcat(data[:,2], data[:,3])[1:numlocs,:]
	
	return loccoords

end

#-----------------------------------------------------------------------------------#

#Create the time-space nodes, returning the number, ids, and descriptions
function createtimespacenodes(numlocs, horizon, tstep)

	nodeid, nodedesc = Dict(), Dict()

	index = 1
	for t in 0:tstep:horizon
		for l in 1:numlocs
			nodeid[l,t] = index
			nodedesc[index] = (l,t)
			index += 1
		end	
	end
	
	numnodes = length(nodeid)
	times = [t for t in 0:tstep:horizon]

	return numnodes, nodeid, nodedesc, times

end

#-----------------------------------------------------------------------------------#

#Read the list of arcs from the arc file
function getphysicalarcs(arcfilename, tstep)

	data = CSV.read(arcfilename, DataFrame)
	
	physicalarcs = []

	for a in 1:size(data)[1]
		l1, l2 = data[a,1], data[a,2]
		if (l1 <= numlocs) & (l2 <= numlocs)
			arcdistance = data[a,4]
			arclength_raw = data[a,3]
			arclength_discretized = tstep * ceil(arclength_raw / tstep)
			push!(physicalarcs, (l1, l2, arcdistance, arclength_raw, arclength_discretized))
		end
	end

	return physicalarcs

end

#-----------------------------------------------------------------------------------#

#Create the time-space network arcs, returning the number, ids, descriptions, and cost of each arc
function createtimespacearcs(physicalarcs, numlocs, numnodes, nodeid)

	arcid, arcdesc, A_plus, A_minus, arccost = Dict(), Dict(), Dict(), Dict(), []
	
	for node in 1:numnodes
		A_plus[node] = []
		A_minus[node] = []
	end

	stationaryarcs = []
	for l in 1:numlocs
		push!(stationaryarcs, (l, l, 0, tstep, tstep))
	end

	index = 1
	for arc in union(physicalarcs, stationaryarcs), t in 0:tstep:horizon-arc[5]
		startnode = nodeid[arc[1],t]
		endnode = nodeid[arc[2],t+arc[5]]
	
		arcid[(startnode,endnode)] = index
		arcdesc[index] = (startnode,endnode)
		
		push!(A_plus[startnode], index)
		push!(A_minus[endnode], index)

		push!(arccost, arc[3])

		index += 1
	end

	numarcs = length(arcid)

	return numarcs, arcid, arcdesc, A_plus, A_minus, arccost

end

#-----------------------------------------------------------------------------------#

#Build the full time-space network
function createfullnetwork(locationfilename, arcfilename, numlocs, horizon, tstep)

	#Build network
	loccoords = readlocations(locationfilename, numlocs)
	numnodes, nodeid, nodedesc, times = createtimespacenodes(numlocs, horizon, tstep)
	physicalarcs = getphysicalarcs(arcfilename, tstep)
	numarcs, arcid, arcdesc, A_plus, A_minus, arccost = createtimespacearcs(physicalarcs, numlocs, numnodes, nodeid)

	#Create a NamedTuple with all the useful network data/parameters
	tsnetwork = (loccoords=loccoords, numnodes=numnodes, nodeid=nodeid, nodedesc=nodedesc, times=times, numarcs=numarcs, arcid=arcid, arcdesc=arcdesc, A_plus=A_plus, A_minus=A_minus, arccost=arccost)

	return tsnetwork, physicalarcs

end