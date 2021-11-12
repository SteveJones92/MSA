include("../src/MSA.jl")

t1 = "AACGTGATTGAC"
t2 = "TCGAGTGCTTTACAGT"
t3 = "GCCGTGCTAGTCG"
t4 = "TTCAGTGGACGTGGTA"
t5 = "GGTGCAGACC"

input_online = [t1, t2, t3, t4, t5]

#-------- Test input
input1 = "MMVHLTPMMKSAVTALWGKVNVDMVGGMALGRLLVVYPWTQRFFMSFGDLSTPDAVM"
input2 = "MMGLSDGMWQLVLNVWGKVMADIPGHGQMVLIRLFKGHPMTLMKFDKFKHLKSMDMMKAS"
input3 = "ALVMDNNAVAVSFSMMQMALVLKSWAILKKDSANIALRFFLKIFMVAPS"
input4 = "MMRPMPMLIRQSWRAVSRSPLMHGTVLFARLFALMPDLLPLFQYNCRQFSSPMD"

input_paperTest_sequence = [ input1, input2, input3, input4]

input10 = "AABB"
input11 = "ACA"
input12 = "CC"

input_shortTest_sequence = [ input10, input11, input12 ]

input13 = "AATGGTCATAGCGAGATGAAGCCACGTGATGGATAATATTGTGCAAACGACCTTATTAGCTATTGACCGTCGATGTCCAACGAGACAATT"
input14 = "GAATCTGTATTCTTCAAGCTTCAACTCCATGCACTACGAACGGTAGTGGTTCACATTGACCGTG"
input15 = "TTGGGCGCATTGACCGTCCTTCCTAGCGTATCATCAAACTTGTGATTCTCTATCTAGAGCAAAATGCGGTGTCCGCTATATGGAGATCTATTTCAAAATA"
input16 = "GTTACATATCAGAATCATTAGAAACGCTCTTAATGGGGTTAAGCAGAGACTTAGTAAGGATTAACTCCCAAGATGATTGACCGTGCTC"

input_project_example = [ input13, input14, input15, input16 ]

input_rand_seq = []
for i = 1:rand(3:10)
    push!(input_rand_seq, randstring("ACGT", rand(10:20)))
end
#--------

# start with input strings
# we want to end up with a useable chromosome representation for the string, which is the positions of the gaps
# we want an initialization for the population first, which gives us this initial set of chromosomes
# we can always use this to rebuild from the original string, so the original string should be carried over
# a fitness function is off of the original string with the gaps in, so we need to reconstruct from the chromosome and the string, the gapped string
# then use the fitness function


# hyper_parameters
score_list = [1, 0, 0]        # match, mismatch, gap penalty
initial_population_size = 10     # currently always the maintained population
gap_growth = 1.16                # after max input length is found, this is used to provide gaps for the max as well, ie [3, 4, 7] would be 7 * 1.2 = 9 (rounded up)
                                # so 2 gaps put in the largest one, 5 in the next, and the 3 sized input would get 6 gaps
elitism_prop = 0.2             # proportion of best to select to keep
num_crossover = 3               # number of crossovers to take as parents for generating against rest
children_cap = 1000          # how many children can be the result of a crossover, "nothing" means there is no cap
generation_count = 1000          # how many times to run through children
mutation_strength = .1        # how much do the gaps shuffle, 1 would be full shuffle
printout = false                 # whether to print out step-wise operation of the MSA to see how it works

#Random.seed!(randomSeed)
                                
#input_sequence = input_rand_seq
#input_sequence = input_paperTest_sequence
#input_sequence = input_online
#input_sequence = input_shortTest_sequence
input_sequence = input_project_example

MSA(input_sequence, score_list, initial_population_size, gap_growth, elitism_prop, num_crossover, children_cap, generation_count, mutation_strength, printout)