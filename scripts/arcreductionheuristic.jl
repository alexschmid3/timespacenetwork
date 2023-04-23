
#Get a list of physical arcs that start from each location l, stored as P_plus[l] (helpful for shortest path)
function prearcPreproc(physicalarcs)

	P_plus = Dict()
	for l in 1:numlocs
		P_plus[l] = []
	end

	for pa in physicalarcs, l in 1:numlocs
		if pa[1] == l
			push!(P_plus[l], (pa[1], pa[2], pa[5])) #(loc1, loc2, rounded travel time)
		end
	end
	
	return P_plus
	
end

#---------------------------------------------------------------------------------------#

function findshortestpath(loc1, loc2, physicalarcs, P_plus)

	#Initialize shortest path algorithm (Dijkstra's)
	visitednodes = zeros(numlocs)
	currdistance = repeat([999999.0],outer=[numlocs])
	currdistance[loc1] = 0
	currloc, nopathexists_flag = loc1, 0

	#Find shortest path from loc1 to loc2
	while (visitednodes[loc2] == 0) & (nopathexists_flag == 0)

		#Assess all neighbors of current node
		for (l1, l2, tt) in P_plus[currloc]
			if (visitednodes[l2] == 0) & (currdistance[currloc] + tt < currdistance[l2] + 1e-4)
				currdistance[l2] = currdistance[currloc] + tt
			end
		end

		#Mark the current node as visited
		visitednodes[currloc] = 1

		#Find a list of unvisited nodes and their current distances 
		currdistance_unvisited = deepcopy(currdistance)
		for l in 1:numlocs
			if visitednodes[l] == 1
				currdistance_unvisited[l] = 999999
			end
		end

		#Update the current node 
		currloc = argmin(currdistance_unvisited)

		#If all remaining nodes have tentative distance of 999999 and the algorithm has not terminated, then there is no path from origin to destination
		if minimum(currdistance_unvisited) == 999999
			nopathexists_flag = 1
		end

	end

	#Return shortest path distance or 999999 if no path exists
	return currdistance[loc2]

end

#---------------------------------------------------------------------------------------#

#Solve shortest path problems between all pairs of locations
function cacheShortestTravelTimes(physicalarcs)
	
	P_plus = prearcPreproc(physicalarcs)

	shortestTravelTime = Dict()
	for loc1 in 1:numlocs, loc2 in 1:numlocs
		if loc1 == loc2
			shortestTravelTime[loc1, loc2] = 0
		else
			#Find the shortest path from loc1 to loc2 with Djikstra's
			shortestTravelTime[loc1, loc2] = findshortestpath(loc1, loc2, physicalarcs, P_plus)
		end
	end

	return shortestTravelTime

end

#---------------------------------------------------------------------------------------#

function findrestrictedarcset(tsn, k, ktype, originloc, origintime, destloc)
	
	#Cache shortest path travel times (used many times later)
	traveltime = cacheShortestTravelTimes(physicalarcs)

	#Set the deadline by which we want to arrive at our destination location
	if ktype == "absolutetime"
		deadline = origintime + traveltime[originloc, destloc] + k
	elseif ktype == "shortestpathpercent"
		deadline = origintime + traveltime[originloc, destloc] + k * traveltime[originloc, destloc]
	end

	#Augment the list of physical arcs with stationary arcs
	physicalarcs_aug = deepcopy(physicalarcs)
	for l in 1:numlocs
		push!(physicalarcs_aug, (l, l, 0, tstep, tstep))
	end

	#Initialize the restricted arc set 
	restrictedArcSet = []

	#Iterate through all arcs
	for arc in physicalarcs_aug
		loc1, loc2, loc1loc2_traveltime = arc[1], arc[2], arc[5]
		
		if loc1 != destloc

			#Get relevant travel times (origin --> loc1, loc1 --> loc2, loc2 --> destination)
			t1 = traveltime[originloc, loc1]
			t2 = loc1loc2_traveltime
			t3 = traveltime[loc2, destloc]

			#Add time-space network arc at each time step t if it meets two criteria:
			#  (i) We could reach loc1 by time t, leaving from origin at time no earlier than origintime
			#  (ii) We could reach destloc by the deadline, after traveling from loc1 to loc2 at time t
			for t in 0:tstep:horizon-t2
				if (origintime + t1 <= t) & (t + t2 + t3 <= deadline)
					push!(restrictedArcSet, tsn.arcid[tsn.nodeid[loc1, t], tsn.nodeid[loc2, t + t2]])			
				end
			end
		end
	end

	return restrictedArcSet

end