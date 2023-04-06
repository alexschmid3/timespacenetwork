
using JuMP, Gurobi, Random, CSV, DataFrames, Statistics, Dates 

#-------------------------------------LOAD SCRIPTS-------------------------------------#

include("scripts/createnetwork.jl")
include("scripts/networkvisualization.jl")

#----------------------------------NETWORK PARAMETERS----------------------------------#  	

#Read experiment parameters 
horizon = 168									#Length of time horizon in hours 
tstep = 6										#Time discretization
numlocs = 20									#Number of physical locations, can choose from 1 to 66 for this dataset
locationfilename = "data/locations.csv"
arcfilename = "data/arcs.csv"
randomseedval = 1906							#Set random seed if there are any random components of an algorithm
Random.seed!(randomseedval)

#-----------------------------------GENERATE NETWORK-----------------------------------# 

#Create node and arc networks
tsnetwork = createfullnetwork(locationfilename, arcfilename, numlocs, horizon, tstep)

#Print some fun facts
println("Initialized time space network with...")
println("Num nodes = ", tsnetwork.numnodes)
println("Num arcs = ", tsnetwork.numarcs)

# All attributes of tsnetwork:
# ---------------------------------#
# loccoords --> array of coordinates for all locations
# numnodes --> total number of nodes
# nodeid --> dictionary, nodes[l, t] = node id for node representing location l at time t 
# nodedesc --> dictionary, nodelookup[n] = (location, time) of node n
# times --> array of discretized time periods
# numarcs --> total number of arcs 
# arcid --> dictionary, arcs[n1, n2] = arc id for arc starting at n1 and ending at n2 (if it exists)
# arcdesc --> dictionary, arclookup[a] = (startnode, endnode) of arc a
# A_plus --> dictionary, A_plus[n] = list of arcs with startnode n (useful for flow-balance constraints)
# A_minus --> dictionary, A_minus[n] = list of arcs with endnode n (useful for flow-balance constraints)
# arccost --> array of cost/distance of each arc
 
#--------------------------------VISUALIZATION EXAMPLE---------------------------------# 

#Get a list of arcs you want to display (usually from optimization solution, but just 50 random arcs for this example)
arclist = [a for a in 1:tsnetwork.numarcs][randperm(tsnetwork.numarcs)[1:min(50, tsnetwork.numarcs)]]
timespaceviz("visualizations/myviz.png", tsnetwork, arclist, x_size=2000, y_size=1000)
