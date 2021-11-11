include("../src/tools.jl")

# test insert_char
testString = insert_char("aaaaa", 2, "A")
@assert(testString == "aAaaaa")

# test build_strings
testSequence = [ "AABB", "ACA", "CC" ]
testChromRep = [ [4], [4, 5], [1, 3, 4] ]
@assert(build_strings(testSequence, testChromRep) == [ "AAB_B", "ACA__", "_C__C" ])

#test gap_counts
gap_counts, len = get_gap_count(testSequence, 1.2)
# need 1, 2, and 3 gaps respectively to reach a length of 5 for each string
# 5 because that is the ceiling of 4 * 1.2, the largest string in the sequence
@assert(gap_counts == [1, 2, 3])
@assert(len == 5)