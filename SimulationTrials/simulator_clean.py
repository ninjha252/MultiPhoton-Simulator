#!/bin/python3

"""
Graph Rep:
	N^2 = number of nodes (nodes {1-n^2})
	Assume a square grid, so each node is connect0 to i-1, i+1, i+n
	A set T |T| >=2 {1,n^2} Union {i} such that node i are trusted nodes
"""
from __future__ import print_function
from ortools.graph import pywrapgraph
import random
import collections
import sys
from copy import deepcopy
from math import log2
import math
import networkx as nx

def shortest_path2(Gra,source, target):
	G = nx.Graph()
	for edge in Gra.get_edges():
		G.add_edge(edge[0], edge[1])
	try:
		return nx.shortest_path(G,source, target)
	except nx.exception.NodeNotFound:
		return ()
	except nx.exception.NetworkXNoPath:
		return ()

class Graph:
	def __init__(self, nodes, edges, weight = lambda u,v: 1):
		self._nodes = tuple([int(node) for node in nodes])
		self._edges = set(edges)
		self._weight = weight 
		
	def print_graph(self):
		print("Vertices: {}".format(self.get_nodes()))
		print("Edges: {}".format([ (x, self.weight(x[0],x[1])) for x in self.get_edges()]))

	def get_edges(self):
		return self._edges

	def weight(self, u,v):
		return self._weight(u,v)

	def get_nodes(self):
		return self._nodes

	def get_edge(self, u, v):
		edge = (min(u,v), max(u,v))
		if edge in self.get_edges():
			return edge
		return False

	def set_edges(self, new_edges):
		self._edges = set(new_edges)

	def set_nodes(self, new_nodes):
		self._nodes = tuple(new_nodes)

	def get_neighbors(self, u):
		return set([v for v in self.get_nodes() if self.get_edge(u,v)])

	def remove_edge(self, u, v):
		e = self.get_edge(u,v)
		if e:
			self.get_edges().remove((e[0],e[1]))
	def add_edge(self, u, v):
		e = self.get_edge(u,v)
		if not e:
			self.get_edges().add((u,v))


	def shortest_path(self, source, dest):
		return shortest_path2(self,source,dest)
	

	def all_paths(self):
		paths = {}
		for u in self.get_nodes():
			for v in self.get_nodes():
				path = self.shortest_path(u,v)
				if u in paths:
					paths[u][v] = len(path) -1 #(len(path)-1, path)
				else:
					paths[u] = {v:len(path) -1} #(len(path)-1, path)}
		self._paths = paths
		return paths

class GridGraph(Graph):
	def __init__(self, n, T, weight=lambda u,v: 1):
		self._n = n
		vert = tuple([i for i in range(0,n*n)])
		edgel = []
		for i in vert:
			if i+1 in vert and (i+1) % n  !=0:
				edgel.append((i, i+1))
			if i+n in vert:
				edgel.append((i, i+n))
		self.trusted = tuple(sorted([int(t) for t in T]))
		super().__init__(vert, edgel)

	def show_graph(self):
		print("")
		n = self._n
		for row in range(n):
			for nodes_or_edge in range(3):
				for col in range(n):
					cur_node = col + row*n 
					if nodes_or_edge == 0:
						#print(cur_node, end = "")
						print("T" if cur_node in self.get_trusted() else "X", end = "")
						if self.get_edge(cur_node, cur_node + 1):
							print(" -- ", end="")
						else:
							print("    ", end="") 
					else:
						if self.get_edge(cur_node, cur_node+n):
							print ("|",end="")
						else:
							pass
							print(" "*max(len(str(cur_node)),len(str(cur_node+n))), end="")
						print("    ",end="")
				
				print("")

	def get_dim(self):
		return self._n
	def get_trusted(self):
		return self.trusted

def generate_network(n,T, p, q, d):
	G = GridGraph(n,T)
	P = {i:{j: p for j in range(0,n**2) if G.get_edge(i,j)} for i in range(0,n**2)}
	D = {i:{j: d for j in range(0,n**2) if G.get_edge(i,j)} for i in range(0,n**2)}
	Q = [q for i in range(n**2)]
	K = {i:{j: 0 for j in G.get_trusted()} for i in G.get_trusted()}
	Kb = {i:{j: "" for j in G.get_trusted()} for i in G.get_trusted()}

	return (G,P,Q,D,K, Kb)

def pair_ent(G, P):
	G1 = GridGraph(G.get_dim(), G.get_trusted()) 
	G1.set_edges([e for e in G.get_edges() if PRNG_gen.random() < P[e[0]][e[1]]])
	return G1

def R1_find_best_links(G,G1,K,node, naive = False):

	neighbors = G1.get_neighbors(node) #these nodes are connected by ent channel to our noe
	trusted = G1.get_trusted()
	dist = lambda x: G._paths[x[0]][x[1]]
	Pt = []
	if len(neighbors) <=1:
		return [] # coudn't add any
	#We have a list of neighbor nodes and unique trsuted nodes, and the distance between them 
	neigh_trusted1 = [(u,T) for u in neighbors for T in trusted]
	#print("Node:", node)
	#print("Dists1: ", neigh_trusted1)
	
	best_dist_1 = dist(min(neigh_trusted1, key=dist)) #this gives us the best distance
	
	Poss1 = [p for p in neigh_trusted1 if dist(p) == best_dist_1]
	#print(Poss1)
	(v1,t1) = PRNG_gen.choice(Poss1)

	neigh_trusted2 = [(u,T) for u in neighbors for T in trusted if T!=t1] # TODO: Does this line mean you can get the same neighbor twice?
	best_dist_2 = dist(min(neigh_trusted2, key=dist)) #this gives us the best distance

	# TODO: Make sure I go with the closest. Naive flag is only to break a tie

	Poss2a = [p for p in neigh_trusted2 if dist(p) == best_dist_2 ]

	Poss2 = [p for p in Poss2a if abs(node-p[0]) == abs(node-v1)]
	if naive or not Poss2 : #if naive flag is set dont try and maintain direction
		Poss2 = Poss2a
	#print(Poss2)
	(v2,t2) = PRNG_gen.choice(Poss2)
	

	if v1 == v2:

		# TODO: Account for third best Trusted node (if same node is close to two)

		#Trying
		next_nt1 = [p for p in neigh_trusted1 if p[0] != v1 and p[1] != t2]
		next_nt2 = [p for p in neigh_trusted2 if p[0] != v2 and p[1] != t1]
		next_best_1 = dist(min(next_nt1, key=dist))
		next_best_2 = dist(min(next_nt2, key=dist))
		next_poss1 = [p for p in next_nt1 if dist(p) == next_best_1]
		next_poss2 = [p for p in next_nt2 if dist(p) == next_best_2]
		(nv1, nt1) = PRNG_gen.choice(next_poss1)
		(nv2, nt2) = PRNG_gen.choice(next_poss1)


		if dist((v1,t1)) + dist((nv2, nt2)) < dist((nv1,nt1)) + dist((v2,t2)):
			v2,t2 = nv2,nt2
		elif dist((v1,t1)) + dist((nv2, nt2)) >dist((nv1,nt1)) + dist((v2,t2)):
			v1,t1 = nv1,nt1
		else:
			which = PRNG_gen.choice([0,1])
			if which:
				v1,t1 = nv1,nt1
			else:
				v2,t2 = nv2,nt2

		if v1 == v2:
			print("Error!")
			print("G")
			G.show_graph()
			print("G1")
			G1.show_graph()
			print("Paths:", G._paths)
			print("node", node)
			print("Poss1: ", Poss1)
			print("Poss2: ", Poss2)
			print("V1, t1, v2, t2: ", v1,t1,v2,t2)

			print("Could we do:")
			print("V1, t1, v2, t2: ", v1,t1,nv2,nt2)
			print("or:")
			print("V1, t1, v2, t2: ", nv1,nt1,v2,t2)
			print(dist((v1,t1)) + dist((nv2, nt2)), dist((nv1,nt1)) + dist((v2,t2)))
			raise RuntimeError("Error, trying to link same node to itself")
	#print(v1,t1, v2,t2)
	Pt.append([min(v1,v2), node, max(v1,v2)])
	#G1.remove_edge(node, v1)
	#G1.remove_edge(node, v2)
	#G1.add_edge(v1,v2)
	neighbors.remove(v1)
	neighbors.remove(v2)
	if len(neighbors)==2:
		Pt.append([min(neighbors), node, max(neighbors)])
		#G1.remove_edge(node, min(neighbors))
		#G1.remove_edge(node, max(neighbors))
		#G1.add_edge(min(neighbors),max(neighbors))
	#print(Pt)

	return Pt

def local_R1(G, G1, K, naive = False): 
	#G1.show_graph()
	trusted = G1.get_trusted()
	Pt = []
	for node in G1.get_nodes():
		if node not in trusted:
			result = R1_find_best_links(G,G1,K,node, naive)
			#print("best links for ", node, result)
			#print(result)
			if result:
				#print("Result," ,result)
				#print("Path", Pt)
				for add in result:
					added = False
					#print("new", add)
					for path in Pt:
						#print(" add, path", add[:-1], path[-2:])
						# [2, 3, /4] == path[/1, 2, 3]
						if add[:-1] == path[-2:]:
							path.append(add[-1])
							added = True
							#print("mrg-",Pt)
					if not added:
						Pt.append(add)


	#print(Pt)
	#raise RuntimeError
	ret = [p for p in Pt if p[0 ] in trusted and p[-1] in trusted]
	for path in ret:
		for pathi in range(len(path)-1):
			G1.remove_edge(path[pathi], path[pathi+1])
	return ret

def R1(G,G1,K):
	trusted =  G.get_trusted()
	Pt = []
	first_flag = False
	#G1.show_graph()
	# print("---")
	while True:
		shortest_paths = []
		for TN1 in trusted:
			for TN2 in trusted:
				if TN1 < TN2:
					shortest_paths.append(G1.shortest_path(TN1, TN2))
		adds = [p for p in shortest_paths if len(p)!=0]
		#print("lens ", [[x[0],x[-1],len(x)] if x else "" for x in shortest_paths])
		#print("Paths", adds)
		mina = min(adds, key = lambda x: len(x)) if adds else []
		#print("mina =", mina)
		adds = [p for p in adds if len(p) == len(mina)]
		#print("chosing from", adds)
		add = PRNG_ran.choice(adds) if adds else []
		#add = adds[-1] if adds else []
		#print("chose", add)
		# print("")
		if add:
			#print("{} -> {} len {}".format(add[0],add[-1], len(add)))
			#print("Adding", add)
			#if len(add) != 7 and ((add[0],add[-1]) == (0,24) or (add[0],add[-1]) == (24,48)):
				# print("Added so far:", [(x,len(x)) for x in Pt])
				# print("Paths", adds)
				# print("mina =", mina)
				# print("chose from", adds)
				# print("Adding", add, len(add))
				# G1.show_graph()
			add = adds[-1] if adds else []
			for j in range(len(add)-1):
				G1.remove_edge(add[j], add[j+1])
			Pt.append(add)
		else:
			#print("Breaking")
			break
	#print("Added ", Pt)
	#print("------")
	#G1.show_graph()
	return Pt

def path_ent(G, Q, D, Pt):

	G2 = GridGraph(G.get_dim(), G.get_trusted())
	G2.set_nodes(G.get_trusted())
	edges = []

	for p in Pt:
		prob_suc = 1
		prob_dep = 1-D[p[0]][p[1]]
		for i in range(len(p[1:-1])):
			pi = p[i]
			pi2 = p[i+1]
			try:
				prob_suc *= Q[pi]

			except:
				print(prob_suc, Q, pi)
			try:
				prob_dep *= (1-D[pi][pi2])
			except:
				print(pi, pi2)
				raise RuntimeError
		prob_dep = prob_dep + (1-prob_dep)/2
		rand = PRNG_ent.random()

		if rand <= prob_suc and p[0] in G2.get_trusted() and p[-1] in G2.get_trusted():
			edges.append((p[0],p[-1], int(PRNG_ent.random() > prob_dep)))
	G2.set_edges([(e[0],e[1]) for e in edges ])
	return G2, edges

def attempt_QKD(G, Ed, Pz, Px, K, Kb):
	for edge in Ed:
		if PRNG_qkd.random() <= Pz*Pz+Px*Px:
			i = min(edge[0], edge[1])
			j = max(edge[0], edge[1])
			K[i][j] +=1
			Kb[i][j]+=str(int(edge[2]))
	G3 = GridGraph(G.get_dim(), G.get_trusted())
	G3.set_nodes(G.get_trusted())
	G3.set_edges(G.get_edges())
	return G3, K, Kb

def R2_regular(G,K,Kb):
	old_K = deepcopy(K)
	old_Kb = deepcopy(Kb)
	for i in K:
		for j in K:
			if not K[i][j]:
				continue

			errors = Kb[i][j].count("1")
			Q = float(errors/K[i][j])
			K[i][j] = max(0,int((1-2*binary_entropy(Q))*K[i][j]))
			Kb[i][j] = "0"*K[i][j]
			try:
				print("		{} - > {} had {} raw bits and {} errors, error rate of {} resulting in {} secret key bits".format(i, j,old_K[i][j],errors,Q, K[i][j]))
			except:		
				print("		{} - > {} had {} bits and {} errors, error rate of {}".format(k, kb, k_errors[k][kb][0],k_errors[k][kb][1],0))
				
			
	#print("+++++++++++++++++++++++++++++++++++++++++++++")
	c=0
	while True:
		c+=1
		#print("-------------------- Loop {} ------------".format(c))
		# print(K)
		start_nodes, end_nodes, capacities = [],[],[]
		for i in K:
			for j in K[i]: #chnaged k to kb
			#if Kb[i][j]:
				start_nodes.append(i)		
				end_nodes.append(j)
				capacities.append(K[i][j])
		# print(start_nodes)
		# print(end_nodes)
		# print(capacities)
		if not (start_nodes and end_nodes and capacities):# or not min(K) in start_nodes or not max(K) in end_nodes:
			return 0, 0, old_K, old_Kb
		flow = maxflow_ortools(start_nodes, end_nodes, capacities)

		##error stuff
		flows = []
		for i in range(flow.NumArcs()):
			for j in range(i,flow.NumArcs()):
				if flow.Head(i) == flow.Tail(j) and (flow.Head(i)!=flow.Tail(i)) and (flow.Flow(j) and flow.Flow(i)):
					# print('	%1s -> %1s   %3s  / %3s' % (flow.Tail(i),flow.Head(i),flow.Flow(i),flow.Capacity(i)))
					# print('	%1s -> %1s   %3s  / %3s' % (flow.Tail(j),flow.Head(j),flow.Flow(j),flow.Capacity(j)))
					flows.append([flow.Tail(i), flow.Head(i), flow.Head(j), flow.Flow(j)])
					#print(flows[-1])
		# print("Flows is ", flows)
		if len(flows) <= 1:
			
			print("	Breaking flows")
			break
		for f in flows:
			# print("consiering at", f)
			if True or not (f[0] == min(K) and f[1] == max(K)):
				try:
					new_str = "".join([str(int(Kb[f[0]][f[1]][i]) ^ int(Kb[f[1]][f[2]][i])) for i in range(f[3])])
					# print("Looking at", f)
				except Exception as e:
					print("Error")
					print("Flow", f)
					print("Kb[{}][{}]".format(f[0],f[1]), Kb[f[0]][f[1]])
					print("Kb[{}][{}]".format(f[1],f[2]), Kb[f[1]][f[2]])
					print(e)
					raise RuntimeError
				# print("1", Kb[f[0]][f[1]])
				# print("2", Kb[f[1]][f[2]])
				# print("xor" ,new_str)

				# print("old", Kb[f[0]][f[2]])
				Kb[f[0]][f[1]] = Kb[f[0]][f[1]][f[3]:]
				Kb[f[1]][f[2]] = Kb[f[1]][f[2]][f[3]:]
				Kb[f[0]][f[2]] += new_str

				K[f[0]][f[1]] -=f[3]
				K[f[1]][f[2]] -=f[3]
				K[f[0]][f[2]] +=f[3]
				# print("old1",Kb[f[0]][f[1]])
				# print("old2",Kb[f[1]][f[2]])

				# print("new",Kb[f[0]][f[2]])
				break
	if flows:
		f= flows[0]
		try:
			new_str = "".join([str(int(Kb[f[0]][f[1]][i]) ^ int(Kb[f[1]][f[2]][i])) for i in range(f[3])])
			# print("Looking at", f)
		except Exception as e:
			print("Error")
			print("Flow", f)
			print("Kb[{}][{}]".format(f[0],f[1]), Kb[f[0]][f[1]])
			print("Kb[{}][{}]".format(f[1],f[2]), Kb[f[1]][f[2]])
			print(e)
			raise RuntimeError
		# print("1", Kb[f[0]][f[1]])
		# print("2", Kb[f[1]][f[2]])
		# print("xor" ,new_str)

		# print("old", Kb[f[0]][f[2]])
		Kb[f[0]][f[1]] = Kb[f[0]][f[1]][f[3]:]
		Kb[f[1]][f[2]] = Kb[f[1]][f[2]][f[3]:]
		Kb[f[0]][f[2]] += new_str

		K[f[0]][f[1]] -=f[3]
		K[f[1]][f[2]] -=f[3]
		K[f[0]][f[2]] +=f[3]
		# print("old1",Kb[f[0]][f[1]])
		# print("old2",Kb[f[1]][f[2]])

		# print("new",Kb[f[0]][f[2]])
	errors = Kb[min(Kb)][max(Kb)].count("1")
	# print("Error string is " ,len(Kb[min(Kb)][max(Kb)]))

	##reset K, Kb
	Kb[min(Kb)][max(Kb)]=""
	for i in range(flow.NumArcs()):
		K[flow.Tail(i)][flow.Head(i)]-=flow.Flow(i)
	#print(Kb)
	#print(K)
	# print("Flows", flows)
	# print("maxflow", flow.OptimalFlow())
	return flow.OptimalFlow(), errors, K, Kb

def maxflow_ortools(start_nodes, end_nodes, capacities):
  """MaxFlow simple interface example."""

  # Define three parallel arrays: start_nodes, end_nodes, and the capacities
  # between each pair. For instance, the arc from node 0 to node 1 has a
  # capacity of 20.

  #start_nodes = []  #[0, 0, 0, 1, 1, 2, 2, 3, 3]
  #end_nodes =   []  #[1, 2, 3, 2, 4, 3, 4, 2, 4]
  #capacities =  []  #[20, 30, 10, 40, 30, 10, 20, 5, 20]
  # Instantiate a SimpleMaxFlow solver.
  max_flow = pywrapgraph.SimpleMaxFlow()
  # Add each arc.
  for i in range(0, len(start_nodes)):
    max_flow.AddArcWithCapacity(start_nodes[i], end_nodes[i], capacities[i])

  # Find the maximum flow between node 0 and node 4.
  try:
	  if max_flow.Solve(min(start_nodes),max(end_nodes) ) == max_flow.OPTIMAL:
	  	
	    # print('Max flow:', max_flow.OptimalFlow())
	    # print('')
	    # print('  Arc    Flow / Capacity')
	    # for i in range(max_flow.NumArcs()):
	    #   print('%1s -> %1s   %3s  / %3s' % (
	    #       max_flow.Tail(i),
	    #       max_flow.Head(i),
	    #       max_flow.Flow(i),
	    #       max_flow.Capacity(i)))
	    # # print('Source side min-cut:', max_flow.GetSourceSideMinCut())
	    # print('Sink side min-cut:', max_flow.GetSinkSideMinCut())
	    pass
	  else:
	    print('There was an issue with the max flow input.')
	    # print(start_nodes)
	    # print(end_nodes)
	    # print(capacities)
	    raise RuntimeError
  except Exception as e:
    print(start_nodes)
    print(end_nodes)
    print(capacities)
    print(e)
    raise RuntimeError

  
  return max_flow


seed1 = "gen"
seed2 = "ran"
seed3 = "ent"
seed4 = "qkd"
PRNG_gen = None
PRNG_ran = None
PRNG_ent = None
PRNG_qkd = None
def main(N, n, T, p, q, d, Pz = 1/2, Px = 1/2, glob=False, naive=False):
	#print(N, n, T, p, q, d, Pz , Px , glob, naive)

	if T is None:
		print("T=", T, "Aborting")
		return -1,1
	global PRNG_gen
	global PRNG_ran
	global PRNG_ent
	global PRNG_qkd
	PRNG_gen = random.Random(uuid.UUID(seed1) if type(seed1) is str else seed1) 
	PRNG_ran = random.Random(uuid.UUID(seed2) if type(seed2) is str else seed2) 
	PRNG_ent = random.Random(uuid.UUID(seed3) if type(seed3) is str else seed3) 
	PRNG_qkd = random.Random(uuid.UUID(seed4) if type(seed4) is str else seed4) 
	#Set Up
	(G,P,Q,D,K,Kb) = generate_network(n,T,p,q,d)
	G.all_paths()
	#print("Network Graph")
	G.show_graph()
	#Ma in Loop
	pathlength1 = 0
	paths1  = 0
	i = 0
	channels = 0
	decohered = 0
	while i < N:
		#if i % 1000 == 0:
		#	print('		{0}\r'.format("Completed {} out of {}".format(i,N)))
		i+=1
		if i % (N/20) == 0 :
			print('|',end="")
		if i == N:
			print("")
		#print("-------Entanglement Graph-----------")
		G1 = pair_ent(G,P)
		#G1.show_graph()
		#print("-------Routing Ent-----------")
		#G1b = deepcopy(G1)
		Pt = R1(G, G1,K) if glob else local_R1(G,G1,K,naive) #for two trusted nodes old global R1 is actually better.
		#Pt = [x for x in Pt if len(x) <= 11]
		#print(Pt)
		pathlength1 += sum([len(x)-1 for x in Pt])
		paths1 += len(Pt)
		

		#print(Pt)
		num = 0
		
		#G1.show_graph()

		#print ("---------Trusted Connections---------\n")
		(G2, Ed) = path_ent(G, Q, D, Pt)
		channels+=len(Ed)
		decohered += sum([x[-1] for x in Ed])

		#print("	", Ed)
		#G2.print_graph()

		#print("\nAttempt QKD\n")

		(G3, K, Kb) = attempt_QKD(G2, Ed, Pz, Px, K, Kb)
		#G3.print_graph()

	k_errors ={k:{k1:(K[k][k1], Kb[k][k1].count("1")) for k1 in Kb[k]} for k in Kb}

	print("")
	data_str = "Data for {} iterations, {}x{} Grid, L = {}, Q = {}, E = {}, Pz = {}, Global Info = {}, TN Type = {}"\
			.format(N, n, n, round(p,3), q, d, Pz, glob if glob else "{}, Smart = {}".format(glob, not naive), "regular")
	print(data_str)
	(maxflow, errors, K, Kb) = R2_regular(G3,K, Kb)
	
	
	print("Final Stats: {} rounds resulted in {} {} key bits with {} errors with {} TNs at {}".format(i, maxflow, "secret", errors, len(T)-2, T))
	print("		Results in {} secret key bits".format( max(0,int((1-2*binary_entropy(float(errors/maxflow)))*maxflow)) if maxflow else 0 ))
	print("Stats")
	print("		Total connections ", paths1)
	print("		Average connections ", paths1/i)
	print("		Average connection length ", pathlength1/paths1 if paths1 else 0)
	print("		Total established channels", channels)
	print("		Total decohered channels", decohered)
	print("		Average channels", channels/i)
	print("		Average decohered", decohered/channels if channels else 0)

	print("   DEBUG: Key Rate = {}".format((max(0,int((1-2*binary_entropy(float(errors/maxflow)))*maxflow)) if maxflow else 0)/N))
	# for k in k_errors:
	# 	for kb in k_errors:
	# 		if k_errors[k][kb][0]:
	# 			try:
	# 				print("pre-		{} - > {} had {} bits and {} errors, error rate of {}".format(k, kb, k_errors[k][kb][0],k_errors[k][kb][1],k_errors[k][kb][1]/k_errors[k][kb][0]))
	# 			except:		
	# 				print("pre-		{} - > {} had {} bits and {} errors, error rate of {}".format(k, kb, k_errors[k][kb][0],k_errors[k][kb][1],0))
	try:
		print("		Overall had {} bits and {} errors, error rate of {}".format(maxflow, errors, errors/maxflow if maxflow else 0))
	except:
		print("		Overall had {} bits and {} errors, error rate of {}".format(maxflow, errors, 0))
	print("")
	return maxflow, errors

def write_data(filename, data):
	with open(filename, "w+") as f:
		f.write("L/N")
		for key in data:
			f.write("{},".format(key))
		f.write("\n")
		for key1 in data:
			for key2 in data[key1]:
				f.write("{},".format(key2))
				for val in data[key1][key2]:
					break

def binary_entropy(Q):
	if Q == 0 or Q==1:
		return 0
	return -Q*log2(Q)-(1-Q)*log2(1-Q)

def print_data(data0, data1):
	for key in data0:
		print("Data for a {}x{} grid".format(key,key))
		print("L,  T0,  T1")
		for key2 in data0[key]:
			print("{}{}, {}, {}".format(key2, " "* (len(str(max(data0[key]))) - len(str(key2))), 
										data0[key][key2], data1[key][key2]))
		print("")

def print_and_write(string,file):
	save = sys.stdout
	
	sys.stdout = file
	print(string)
	sys.stdout.flush()

	sys.stdout = save
	print(string)

def print_save_data(data_array, header_array, data_str, var, file):
	print_and_write("\"{}\"".format(data_str), file)
	header = "{}, ".format(var) + ", ".join(header_array)
	print_and_write(header, file)
	for v in data_array[0].keys():
		line = "{}, ".format(v) + ", ".join([str(d[v]) for d in data_array])
		print_and_write(line, file)

	return

def gather_data(glob, naive, fixed_len, N, size, L, Q, E, Pz, Px, var, file, asym = False):
	
	if var != "S":
		Trusted0 = [0, size*size-1]
		Trusted1 = [0, int((size*size-1)/2), size*size-1]
		Trusted2 = [0, size-1, size*(size-1), size*size-1]
		Trusted3 = [0, math.floor(size/3)*(size+1),size*size-1-math.floor(size/3)*(size+1), size*size-1]
		Trusted4 = [0, int((size*size-1)/2)-size-1, int((size*size-1)/2), size*size-1]
		Trusted5 = [0, (size+1)*2, (size*size-1)-(size+1)*2, size*size-1]
		
		
		# Trusted0 = None
		# # Trusted1 = None
		# Trusted2 = None
		# Trusted3 = None
		# Trusted4 = None
		# Trusted5 = None

		#v = size
		
	alpha = .15
	if var != "P" and var != "S":
		P = 10**-(alpha*(L/size)/10) if fixed_len else 10**-(alpha*L/10)

		#Trusted1 = [0, size*size-size, size*size-1]
	t0 = {}
	t1 = {}
	t2 = {}
	t3 = {}
	t4 = {}
	t5 = {}

	# todo https://youtu.be/Psk2tWArczc
	# todo touch base on Tue
	# todo work on Global router with multiple trusted nodes
	

	if   var == "P":
		data_str = "Data for {} iterations, {}x{} Grid, L = {}, Q = {}, E = {}, Pz = {}, Global Info = {}, TN Type = {}"\
			.format(N, size, size, "var", Q, E, Pz, glob if glob else "{}, Smart = {}".format(glob, not naive), "regular" )
		print(data_str)
		for v in L:
			P = 10**-(alpha*(v/size)/10) if fixed_len else 10**-(alpha*v/10)
			print("L={}	P = {}".format(v, P))
			print("       ",end=""); t0[v] = main(N,size, Trusted0, P, Q ,E, Pz, Px, glob, naive)
			print("       ",end=""); t1[v] = main(N,size, Trusted1, P, Q, E, Pz, Px, glob, naive)
			print("       ",end=""); t2[v] = main(N,size, Trusted2, P, Q, E, Pz, Px, glob, naive)
			print("       ",end=""); t3[v] = main(N,size, Trusted3, P, Q, E, Pz, Px, glob, naive)
			print("       ",end=""); t4[v] = main(N,size, Trusted4, P, Q, E, Pz, Px, glob, naive)
			print("       ",end=""); t5[v] = main(N,size, Trusted5, P, Q, E, Pz, Px, glob, naive)
	elif var == "Q":
		data_str = "Data for {} iterations, {}x{} Grid, L = {}, Q = {}, E = {}, Pz = {}, Global Info = {}, TN Type = {}"\
				.format(N, size, size, round(L,3), "var", E, Pz, glob if glob else "{}, Smart = {}".format(glob, not naive), "regular")
		print(data_str)
		for v in Q:
			print("	Q = {}".format(v))
			print("       ",end=""); t0[v] = main(N,size, Trusted0, P, v ,E, Pz, Px, glob, naive)
			print("       ",end=""); t1[v] = main(N,size, Trusted1, P, v, E, Pz, Px, glob, naive)
			print("       ",end=""); t2[v] = main(N,size, Trusted2, P, v, E, Pz, Px, glob, naive)
			print("       ",end=""); t3[v] = main(N,size, Trusted3, P, v, E, Pz, Px, glob, naive)
			print("       ",end=""); t4[v] = main(N,size, Trusted4, P, v, E, Pz, Px, glob, naive)
			print("       ",end=""); t5[v] = main(N,size, Trusted5, P, v, E, Pz, Px, glob, naive)
	elif var == "E":
		data_str = "Data for {} iterations, {}x{} Grid, L = {}, Q = {}, E = {}, Pz = {}, Global Info = {}, TN Type = {}"\
			.format(N, size, size, round(L,3), Q, "var", Pz, glob if glob else "{}, Smart = {}".format(glob, not naive), "regular")
		print(data_str)
		for v in E:
			print("	E = {}".format(v))
			print("       ",end=""); t0[v] = main(N,size, Trusted0, P, Q ,v, Pz, Px, glob, naive)
			print("       ",end=""); t1[v] = main(N,size, Trusted1, P, Q, v, Pz, Px, glob, naive)
			print("       ",end=""); t2[v] = main(N,size, Trusted2, P, Q, v, Pz, Px, glob, naive)
			print("       ",end=""); t3[v] = main(N,size, Trusted3, P, Q, v, Pz, Px, glob, naive)
			print("       ",end=""); t4[v] = main(N,size, Trusted4, P, Q, v, Pz, Px, glob, naive)
			print("       ",end=""); t5[v] = main(N,size, Trusted5, P, Q, v, Pz, Px, glob, naive)
	elif var == "S":
		data_str = "Data for {} iterations, {}x{} Grid, L = {}, Q = {}, E = {}, Pz = {}, Global Info = {}, TN Type = {}"\
			.format(N, "var", "var", L, Q, E, Pz, glob if glob else "{}, Smart = {}".format(glob, not naive), "regular")
		print(data_str)
		for v in size:
			Trusted0 = [0, v*v-1]
			Trusted1 = [0, int((v*v-1)/2), v*v-1]
			Trusted2 = [0, v-1, v*(v-1), v*v-1]
			Trusted3 = [0, math.floor(v/3)*(v+1),v*v-1-math.floor(v/3)*(v+1), v*v-1]
			Trusted4 = [0, int((v*v-1)/2)-v-1, int((v*v-1)/2), v*v-1]
			Trusted5 = [0, (v+1)*2, (v*v-1)-(v+1)*2, v*v-1]
			if len(set(Trusted5)) == 3:
				Trusted5 = [0, (v+1)*1, (v*v-1)-(v+1)*1, v*v-1]
		
			# Trusted0 = None
			# Trusted1 = None
			Trusted2 = None
			Trusted3 = None
			Trusted4 = None
			Trusted5 = None

			P = 10**-(alpha*(L/v)/10) if fixed_len else 10**-(alpha*L/10)
			print("	Size = {}".format(v))
			print("       ",end=""); t0[v] = main(N, v, Trusted0, P, Q ,E, Pz, Px, glob, naive)
			print("       ",end=""); t1[v] = main(N, v, Trusted1, P, Q, E, Pz, Px, glob, naive)
			print("       ",end=""); t2[v] = main(N, v, Trusted2, P, Q, E, Pz, Px, glob, naive)
			print("       ",end=""); t3[v] = main(N, v, Trusted3, P, Q, E, Pz, Px, glob, naive)
			print("       ",end=""); t4[v] = main(N, v, Trusted4, P, Q, E, Pz, Px, glob, naive)
			print("       ",end=""); t5[v] = main(N, v, Trusted5, P, Q, E, Pz, Px, glob, naive)
	elif var == None:
		data_str = "Data for {} iterations, {}x{} Grid, L = {}, Q = {}, E = {}, Pz = {}, Global Info =  {}"\
			.format(N, size, size, round(L,3), Q, E, Pz, glob if glob else "{}, Smart = {}".format(glob, not naive), "regular")
		print(data_str)
		v = "N/A"
		print("       ",end=""); t0[v] = main(N,size, Trusted0, P, Q ,E, Pz, Px, glob, naive)
		print("       ",end=""); t1[v] = main(N,size, Trusted1, P, Q, E, Pz, Px, glob, naive)
		print("       ",end=""); t2[v] = main(N,size, Trusted2, P, Q, E, Pz, Px, glob, naive)
		print("       ",end=""); t3[v] = main(N,size, Trusted3, P, Q, E, Pz, Px, glob, naive)
		print("       ",end=""); t4[v] = main(N,size, Trusted4, P, Q, E, Pz, Px, glob, naive)
		print("       ",end=""); t5[v] = main(N,size, Trusted5, P, Q, E, Pz, Px, glob, naive)

	else:
		print("{} data is not supported, can only vary P, Q, E, or S")

	err0 = {v: t0[v][1]/max(t0[v][0],1) if t0[v][0] > 0 else "N/A" for v in t0}
	err1 = {v: t1[v][1]/max(t1[v][0],1) if t1[v][0] > 0 else "N/A" for v in t1}
	err2 = {v: t2[v][1]/max(t2[v][0],1) if t2[v][0] > 0 else "N/A" for v in t2}
	err3 = {v: t3[v][1]/max(t3[v][0],1) if t3[v][0] > 0 else "N/A" for v in t3}
	err4 = {v: t4[v][1]/max(t4[v][0],1) if t4[v][0] > 0 else "N/A" for v in t4}
	err5 = {v: t5[v][1]/max(t5[v][0],1) if t5[v][0] > 0 else "N/A" for v in t5}

	key_rate0 = {v: max(0,1-2*binary_entropy(err0[v])) if err0[v] != "N/A" else 0 for v in err0}
	key_rate1 = {v: max(0,1-2*binary_entropy(err1[v])) if err1[v] != "N/A" else 0 for v in err1}
	key_rate2 = {v: max(0,1-2*binary_entropy(err2[v])) if err2[v] != "N/A" else 0 for v in err2}
	key_rate3 = {v: max(0,1-2*binary_entropy(err3[v])) if err3[v] != "N/A" else 0 for v in err3}
	key_rate4 = {v: max(0,1-2*binary_entropy(err4[v])) if err4[v] != "N/A" else 0 for v in err4}
	key_rate5 = {v: max(0,1-2*binary_entropy(err5[v])) if err5[v] != "N/A" else 0 for v in err5}

	eff_rate0 = {v: key_rate0[v]*t0[v][0]/(4*N) for v in key_rate0}
	eff_rate1 = {v: key_rate1[v]*t1[v][0]/(4*N) for v in key_rate1}
	eff_rate2 = {v: key_rate2[v]*t2[v][0]/(4*N) for v in key_rate2}
	eff_rate3 = {v: key_rate3[v]*t3[v][0]/(4*N) for v in key_rate3}
	eff_rate4 = {v: key_rate4[v]*t4[v][0]/(4*N) for v in key_rate4}
	eff_rate5 = {v: key_rate5[v]*t5[v][0]/(4*N) for v in key_rate5}


	keybits_rate0 = {v: t0[v][0]/N for v in key_rate0}
	keybits_rate1 = {v: t1[v][0]/N for v in key_rate1}
	keybits_rate2 = {v: t2[v][0]/N for v in key_rate2}
	keybits_rate3 = {v: t3[v][0]/N for v in key_rate3}
	keybits_rate4 = {v: t4[v][0]/N for v in key_rate4}
	keybits_rate5 = {v: t5[v][0]/N for v in key_rate5}

	# header_array = ["keybits_rate0", "keybits_rate1", "keybits_rate2", "keybits_rate3","effective_keyrate0", "effective_keyrate1", "effective_keyrate2", "effective_keyrate3", "keyrate0", "keyrate1", "keyrate2", "keyrate3", "errrate0", "errate1","errrate2", "errate3", "keybits0, errors0", "keybits1, errors1", "keybits2, errors2", "keybits3, errors3"]
	# data_array = [keybits_rate0, keybits_rate1, keybits_rate2, keybits_rate3,eff_rate0, eff_rate1, eff_rate2, eff_rate3, key_rate0, key_rate1,key_rate2, key_rate3, err0, err1,err2, err3, {p: t0[p][0] for p in t0},{p: t0[p][1] for p in t0}, {p: t1[p][0] for p in t1}, {p: t2[p][1] for p in t2}, {p: t3[p][0] for p in t3}]
	header_array = ["NoTN", "Central", "Corner", "Diagonal", "Asym", "2Hops"]
	data_array = [keybits_rate0, keybits_rate1, keybits_rate2, keybits_rate3, keybits_rate4, keybits_rate5]
	print_save_data(data_array, header_array, data_str, var, file)
	return eff_rate0, eff_rate1

def gather_all_data(data_file, log_file):
	N = 100000

	size = 7
	L = 10
	Q = .85
	E = .02

	glob = False
	naive = True
	fixed_len = True
	simple = False

	Pz = 1/2
	Px = 1 - Pz

	size_range = [5,7,9,11,13]
	L_range = [1,3,5,10,15]
	Q_range = [1,.95, .85, .75, .65][::-1]
	E_range = [0, .02, .035, .05, .065]
	filename = "all"+data_file
	with open(filename, "w+") as f:
		T0p, T1p = gather_data(glob, naive,fixed_len, N, size, L_range, Q, E, Pz, Px, "P", f)
		T0q, T1q = gather_data(glob, naive,fixed_len, N, size, L, Q_range, E, Pz, Px, "Q", f)
		T0e, T1e = gather_data(glob, naive,fixed_len, N, size, L, Q, E_range, Pz, Px, "E", f)
		T0e, T1e = gather_data(glob, naive,fixed_len, N, size_range, L, Q, E, Pz, Px, "S", f)

import sys
import uuid

seed1 = uuid.uuid4()
seed2 = uuid.uuid4()
seed3 = uuid.uuid4()
seed4 = uuid.uuid4()
# seed1 = "9af02945-634d-4457-8059-24ee16a6ea36"
# seed2 = "6ecd5129-cc03-4972-8330-d982e70ef7b8"
# seed3 = "9965acb6-23ac-40f1-8508-00368225348d"
# seed4 = "66e2caee-f28a-4c93-8318-97f8e3b6854a"
print("seed1 ", seed1)
print("seed2 ", seed2)
print("seed3 ", seed3)
print("seed4 ", seed4)
if __name__ == '__main__':
	BSM_rate = .85
	fiber_length = 1 #km
	transmit_prob =  10.**(-.15*fiber_length/10)
	decoherence_prob = .02
	its = 10000
	#main(its, 3, [0,8], transmit_prob, BSM_rate, decoherence_prob, glob=True, naive = False)
	#main(its, 5, [0,12,24], transmit_prob, BSM_rate, decoherence_prob, glob=True, naive = False)
	main(its, 5, [0,24], transmit_prob, BSM_rate, decoherence_prob, glob=True, naive = False)
	#main(its, 7, [0,16,32,48], transmit_prob, BSM_rate, decoherence_prob, glob=True, naive = False)
	
	#gather_all_data("data.csv", "log_data.txt")
	
		
