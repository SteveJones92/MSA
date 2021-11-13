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
initial_population_size = 100     # currently always the maintained population
gap_growth = 1.16                # after max input length is found, this is used to provide gaps for the max as well, ie [3, 4, 7] would be 7 * 1.2 = 9 (rounded up)
                                # so 2 gaps put in the largest one, 5 in the next, and the 3 sized input would get 6 gaps
elitism_prop = 0.2             # proportion of best to select to keep
num_crossover = 3               # number of crossovers to take as parents for generating against rest
children_cap = 100          # how many children can be the result of a crossover, "nothing" means there is no cap
generation_count = 2000          # how many times to run through children
mutation_strength = 0.03        # how much do the gaps shuffle, 1 would be full shuffle
crossover_criteria = 1          # save children from crossover when they are greater than 1 = average, 2 = worst, 3 = best of the 2 parents
crossover_version = 1           # which type of crossover to use, 1 = random cuts and always left/right, 2 = random cuts and random left/right mix
return_early = false            # if true, returns when children cap is met, otherwise when trying to add a new child, sort and pop off the worst
printout = false                 # whether to print out step-wise operation of the MSA to see how it works
                                
#input_sequence = input_rand_seq
#input_sequence = input_paperTest_sequence
#input_sequence = input_online
#input_sequence = input_shortTest_sequence
input_sequence = input_project_example

MSA(input_sequence, score_list, initial_population_size, gap_growth, elitism_prop, num_crossover, children_cap, generation_count, mutation_strength,
    crossover_criteria, crossover_version, return_early, printout)

# code for checking an output score with the gaps inserted - as in the project description or a built string
# MSA outputs to a file the best result of the run at the end
#=
function score_sequence(input_sequence_set, sequence_length, score_list)
    score = 0
    score_buffer = 0
    item_one = nothing
    item_two = nothing
    num_items = length(input_sequence_set)

    # go through sequence length, to index by column, all input sequences + gaps should = sequence length
    for i = 1:sequence_length
        score_buffer = 0

        for j = 1:num_items
            for k = j + 1:num_items
                # get either a blank space or the character
                if input_sequence_set[j][i] == '_' || input_sequence_set[k][i] == '_' || input_sequence_set[j][i] == '-' || input_sequence_set[k][i] == '-'
                    if input_sequence_set[j][i] != input_sequence_set[k][i]
                        score_buffer += score_list[3]
                    end
                elseif input_sequence_set[j][i] == input_sequence_set[k][i]
                    score_buffer += score_list[1]
                else
                    score_buffer += score_list[2]
                end
            end
        end

        score += score_buffer
    end

    return score
end


i1 = "AATGGTCATAGC------------G-----AGATGA--AG-CCACGTGATGGATAATATTGTGCAAACGACCTTATTAGCT---ATTGACCGTCGATGTCCAACGAGACAAT---T"
i2 = "GAATC-------------------T-----GTATTCTTC--AA-GCTTCAACTC-----CAT--------------GCACT---ACGAACGGTAGTGGTTCACATTGACCGT---G"
i3 = "TTGGG-CGCATTGACCGTCCTTCCTAGCGTATCATC--AAACT-TGTGATTCTCTATCTAGAGCAAAATGCGGTGTCCGCT---AT-----AT-GGAGATCTATTTCAAAAT---A"
i4 = "GTTA--CATATC------------A---GAATCATT--AG-AAACGCTCTTAATGGGGTTAAGCAGAG-AC-TTAGTAAGGATTAACTCCCAA-GATGATT-----GACCGTGCTC"

i5 = "_AATG_GTCA_TAGCGA_G_A_T__G__AAGC_CACG_TGATGGATA__AT_ATTGTGCAAAC__G_ACCTTATTA_GCTATT_GA_CCG_TCGAT_G__TCCAACGAGA_CAATT"
i6 = "G_A_A__TC__T_G_TAT_T_CTT__C_AAG__C__T_TCA__ACTCC_ATG___CA_C__T_____ACG__A__A__CGG_TAG_T__G___G_T_T_CA_CA_TT_GACC_GTG"
i7 = "TTGGGCG_CATT_GAC_CGTCCTT_CCT_AG__C_GTATCATCAAACTTGTGATTCT_CTATCTAG_A_GC_AAAATGCGG_T_G_TCCGCTATATGGAGATCTATTTCAA_AATA"
i8 = "GT_TACAT_ATCAGA_ATC_A_TTAG__AAACGCTCT_TAATGG_G___GTTA___AGC_A__GAG_AC_TTAGTAAG_GATTAACTCC_CAAGAT_GA_TTGA_CC_GTGC__TC"

sequence = [i1, i2, i3, i4]
sequence2 = [i5, i6, i7, i8]

println(score_sequence(sequence, length(sequence[1]), score_list))
println(score_sequence(sequence2, length(sequence2[1]), score_list))
=#
