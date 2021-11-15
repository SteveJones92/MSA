using Random
include("tools.jl")

# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# creates a number of gaps to fill a certain string length randomly
# the gaps are index positions in sorted order as the function it
# serves is to strings with gaps to a certain length depending on missing
# items, like 'aa' and 'bbb' going to size 4 would need 2 gaps for 'aa' and
# 1 gap for 'bbb', but without duplication it is fine to assume insertions
# because for 'aa', we could only at worst get (3, 4) for size 4, so putting
# incrementally adding the gaps works by placing at end or inserting into
# existing index, benefit of this one is it ends sorted
function create_random_more_gaps(number_of_gaps, string_length)
    # fill [1, 2, 3, ..., string_length]
    my_range = collect(Int64, 1:string_length)

    # delete items randomly until number of gaps remain
    for i = 1:string_length - number_of_gaps
        deleteat!(my_range, Int(rand(1:string_length)))
        string_length -= 1
    end

    return my_range
end

# same as above, but puts gaps into a new list, instead of deleting from
# until gaps remain, above is bad when list is large and gaps are small
# this scales better for very large strings, assuming portion of gaps is
# not large as well, but this ends unsorted which is a downside - added sort
function create_random_less_gaps(number_of_gaps, string_length)
    # fill [1, 2, 3, ..., string_length]
    my_range = collect(Int64, 1:string_length)
    gap_list = []

    # delete items randomly until number of gaps remain
    for i = 1:number_of_gaps
        index = Int(rand(1:string_length))
        push!(gap_list, my_range[index])
        deleteat!(my_range, index)
        string_length -= 1
    end

    return sort!(gap_list)
end

# score using the gap list and the sequence
function score_gap_list(input_sequence_set, gap_list, sequence_length, score_list)
    score = 0

    num_items = length(input_sequence_set)

    # start offsets for accessing with respect to current index,
    # ex: [AAA] w/ gap [2,3] = [A__AA] - a 5 item string
    # but instead of building string, we want to look at A, then gap of 2, 3, then AAA
    # so index will be 1-5, when needing second A, which should be index 4, offsets will be
    # +2 gap_list, -2 sequence_list, so index of 4 will give 2 into sequence_list and show
    # that we've looked past the end of the gap list (because we already had 2 gaps)
    gap_offset_list = fill(0, num_items)

    # make the last item an overflow position
    for i = 1:num_items
        push!(gap_list[i], 0)
    end

    # save variable allocation later
    score_buffer = 0
    item_one = nothing
    item_two = nothing

    # go through sequence length, to index by column, all input sequences + gaps should = sequence length
    for i = 1:sequence_length
        score_buffer = 0

        # go through each input sequence, which is a single line of characters
        # last one will just pass through, either not doing a score or it was a gap
        # so that gap count and offset still needs to increase
        for j = 1:num_items
            # get either a gap or the character
            # if it is a gap, this layer is all gap gap_penalty
            # so save a lot of calculation by mult and continue
            if i == gap_list[j][1 + gap_offset_list[j]]
                gap_offset_list[j] += 1
                item_one = '_'
            else
                item_one = input_sequence_set[j][i - gap_offset_list[j]]
            end

            # go through each input seqence from the next item up to the last
            # final pattern of access = [1, 2, 3] => 12, 13, 23
            for k = j + 1:num_items
                # get either a blank space or the character
                if i == gap_list[k][1 + gap_offset_list[k]]
                    item_two = '_'
                else
                    item_two = input_sequence_set[k][i - gap_offset_list[k]]
                end

                if item_one == '_' || item_two == '_'
                    if item_one != item_two
                        score_buffer += score_list[3]
                    end
                    continue
                end

                if (item_one == item_two)
                    score_buffer += score_list[1]
                else
                    score_buffer += score_list[2]
                end
            end
        end

        score += score_buffer
    end

    # remove the added overflow position
    for i = 1:num_items
        pop!(gap_list[i])
    end

    return score
end

# "save" some of the population for next generation, optionally return a modified input list
function elitism(chrom_pop_fitness, proportion, children_cap)
    num_items = Int(ceil(length(chrom_pop_fitness) * proportion))

    # return the leftover as in the paper
    #return [chrom_pop_fitness[1:num_items], chrom_pop_fitness[num_items + 1:length(chrom_pop_fitness)]]

    # returns the original list back, better results
    return [chrom_pop_fitness[1:min(children_cap, num_items)], chrom_pop_fitness]
end

# take the population and create children off of random points left and right combined
# against the rest of the population by an amount num_best
# ex: 5 would take the first 5 and make children with the rest
# if a cap is specified, stops when enough accepted children are added
# children only accepted if higher score than highest or lowest parent (design decision)
# original population dies off, only children returned
function crossover(input_sequence, population, num_best, cap, len, score_list, criteria, return_early)
    ret_children = []
    input_length = length(input_sequence)

    for i = 1:num_best
        for j = i + 1:length(population)
            cut = Int(rand(1:input_length - 1))

            child1 = []
            child2 = []
            append!(child1, population[i][2][1:cut])
            append!(child1, population[j][2][cut + 1:input_length])
            append!(child2, population[j][2][1:cut])
            append!(child2, population[i][2][cut + 1:input_length])
            
            child1_w_fitness = [ score_gap_list(input_sequence, child1, len, score_list), child1 ]
            child2_w_fitness = [ score_gap_list(input_sequence, child2, len, score_list), child2 ]
            
            if criteria == 1
                # average of the 2
                fitness_criteria = (population[i][1] + population[j][1]) / 2
            elseif criteria == 2
                # score of worst of 2 parents
                fitness_criteria = min(population[i][1], population[j][1])
            else
                # score of best of 2 parents
                fitness_criteria = max(population[i][1], population[j][1])
            end
            
            if (child1_w_fitness[1] > fitness_criteria)
                push!(ret_children, child1_w_fitness)
            end
            
            if (child2_w_fitness[1] > fitness_criteria)
                push!(ret_children, child2_w_fitness)
            end

            # not exact, because 2 children are made but this check is done once
            if !isnothing(cap) && length(ret_children) > cap
                if return_early
                    return ret_children
                end

                sort!(ret_children, by = x -> (x[1]), rev = true)
                pop!(ret_children)
                pop!(ret_children)
            end
        end
    end
    return ret_children
end

# the difference to crossover 1 is this picks one or the other randomly
# for each cut, instead of left right on all
function crossover2(input_sequence, population, num_best, cap, len, score_list, criteria, return_early)
    ret_children = []
    input_length = length(input_sequence)

    for i = 1:num_best
        for j = i + 1:length(population)
            child1 = []
            child2 = []

            current = [ i, j ]
            
            for k = 1:input_length
                shuffle!(current)
                push!(child1, population[current[1]][2][k])
                push!(child2, population[current[2]][2][k])
            end
            
            child1_w_fitness = [ score_gap_list(input_sequence, child1, len, score_list), child1 ]
            child2_w_fitness = [ score_gap_list(input_sequence, child2, len, score_list), child2 ]
            
            if criteria == 1
                # average of the 2
                fitness_criteria = (population[i][1] + population[j][1]) / 2
            elseif criteria == 2
                # score of worst of 2 parents
                fitness_criteria = min(population[i][1], population[j][1])
            else
                # score of best of 2 parents
                fitness_criteria = max(population[i][1], population[j][1])
            end
            
            if (child1_w_fitness[1] > fitness_criteria)
                push!(ret_children, child1_w_fitness)
            end
            
            if (child2_w_fitness[1] > fitness_criteria)
                push!(ret_children, child2_w_fitness)
            end

            # not exact, because 2 children are made but this check is done once
            if !isnothing(cap) && length(ret_children) > cap
                if return_early
                    return ret_children
                end

                sort!(ret_children, by = x -> (x[1]), rev = true)
                pop!(ret_children)
                pop!(ret_children)
            end
        end
    end
    return ret_children
end

# needs input sequence for rescoring, children population, and a mutation string_length
# as well as segment length to pick the random number for each new mutation item
function mutate(input_sequence, children_population, mutation_strength, mutation_chance, segment_length, score_list)
    index_list_mutation = []
    rand_index = 0

    # for every child
    for i = 1:length(children_population)
        # only half the time do a small mutation
        # otherwise keep it
        if rand() < mutation_chance
            continue
        end

        # for every gap list in every child
        for j = 1:length(children_population[i])
            randsubseq!(index_list_mutation, 1:length(children_population[i][j]), mutation_strength)

            for k = 1:length(index_list_mutation)
                rand_index = Int(rand(1:segment_length))
                while rand_index in children_population[i][j]
                    rand_index = Int(rand(1:segment_length))
                end

                children_population[i][j][index_list_mutation[k]] = rand_index
            end
            sort!(children_population[i][j])
        end
    end

    children_population_scored = get_fitness_population(input_sequence, children_population, segment_length, score_list)

    return children_population_scored
end

#---------------------------------------------------------------------------------------------------------------------------------------------------------------------------

# create a number of gap lists representing a chromosome population
# that will work by taking the list of number of gaps to needed
# and the length of the final string
# ex: [ AAA, BBBB, C ] = lengths [ 3, 4, 1 ]
# ex: length = 5, then we would get counts of [2, 1, 4]
# as many times as population size
function create_gap_population(gap_counts, final_length, population_size)
    population = []
    
    for i = 1:population_size
        push!(population, create_gap_list(gap_counts, final_length))
    end

    return population
end

# take a list of gaps ex: [2, 1, 4]
# give a final length ex: 5
# create a number of gaps randomly in the range up to length
# that would pad the current length to that amount
# ex: [ [1, 4], [3], [1, 2, 4, 5] ]
function create_gap_list(gap_counts, final_length)
    median = final_length / 2

    gap_list = []
    # go through each number of gaps to create
    for i = 1:length(gap_counts)
        # when large number of gaps compared to final size, do first, otherwise do second
        if gap_counts[i] > median
            # deletes from index list of final_length until number of gaps remain
            # ends sorted for us
            push!(gap_list, create_random_more_gaps(gap_counts[i], final_length))
        else
            # create new list from index list by selecting randomly until gap count is reached
            # needs to sort at end
            push!(gap_list, create_random_less_gaps(gap_counts[i], final_length))
        end
    end

    return gap_list
end

function get_fitness_population(input_sequence, gap_population, len, score_list)
    gap_pop_w_fitness = []

    for i = 1:length(gap_population)
        push!(gap_pop_w_fitness, [score_gap_list(input_sequence, gap_population[i], len, score_list), gap_population[i]])
    end
    
    # needs to be sorted, for easy checking of best scores
    #sort!(gap_pop_w_fitness, by = x -> (x[1]), rev = true)
    
    return gap_pop_w_fitness
end

function print_fitness_population(input_sequence, fitness_population)
    out = ""
    for i = 1:length(fitness_population)
        out = string(out, fitness_population[i][1], ", ")
    end
    out = string(out, "\n")

    strings_list = []

    for i = 1:length(fitness_population)
        push!(strings_list, build_strings(input_sequence, fitness_population[i][2]))
    end

    for i = 1:length(input_sequence)
        for j = 1:length(strings_list)
            out = string(out, strings_list[j][i], "   ")
        end
        out = string(out, "\n")
    end
    print(out)
    return out
end

function MSA(input_sequence, score_list, init_pop_size, gap_growth, elitism_proportion,
             num_crossover, children_cap, generation_count, mutation_strength, crossover_criteria, crossover_version, return_early, mutation_chance, printout)


    # get the gaps needed to increase each string to a calculated length
    gap_counts, len = get_gap_count(input_sequence, gap_growth)

    # print the gap count and length
    if printout
        # show gap counts and len
        print("Gaps needed to extend sequences to a given calculated length.", '\n')
        print(gap_counts, '\n')
        print(len, '\n')
        print('\n')
    end

    # initialize the first population, return it's chromosome representation
    @time chrom_rep_population = create_gap_population(gap_counts, len, initial_population_size)

    # print the randomized chromosome representation population
    if printout
        print("The population of random gap positions that make new sequence alignments.", '\n')
        # show the randomized population
        for i = 1:length(chrom_rep_population)
            println(chrom_rep_population[i], '\n')
        end
        println()
    end

    # get list of the chromosome representations sorted by fitness
    fitness_population = get_fitness_population(input_sequence, chrom_rep_population, len, score_list)

    # it is unsorted at this point
    sort!(fitness_population, by = x -> (x[1]), rev = true)

    # print the score of the populations and the reconstructed strings
    if printout
        print("The first populations score and associated strings.", '\n')
        print_fitness_population(input_sequence, fitness_population)
        print('\n')
    end

    # now we have a list with fitness values, start building generations
    # and operating on them
    while generation_count >= 1
        if printout
            print("Generation: ", generation_count)
            print("-----------------------------------------------------------", '\n')
        end
        # elitism, select a proportion of these
        fitness_population, original_population = elitism(fitness_population, elitism_prop, children_cap)

        if printout
            print("The elitism selection.", '\n')
            print_fitness_population(input_sequence, fitness_population)
            print("The population subject to crossover.", '\n')
            print_fitness_population(input_sequence, original_population)
            print('\n')
        end

        # do crossover on best, plus some of rest depending on the number of crossover
        if crossover_version == 1
            children = crossover(input_sequence, original_population, num_crossover, children_cap, len, score_list, crossover_criteria, return_early)
        else
            children = crossover2(input_sequence, original_population, num_crossover, children_cap, len, score_list, crossover_criteria, return_early)
        end


        if printout
            println("New children: ",  length(children), '\n')
        end

        # remove score for mutation, which will rescore
       children_unscored = []

        # TODO see all where not doing a deepcopy will effect the outcome
       for i = 1:length(children)
           push!(children_unscored, deepcopy(children[i][2]))
       end

        if printout
            print("Crossed over children.", '\n')
            print_fitness_population(input_sequence, children[1:min(end, 20)])
            print('\n')
        end

        # do a mutation on children, return scored
        children = mutate(input_sequence, children_unscored, mutation_strength, mutation_chance, len, score_list)

        if printout
            print("Mutated crossed over children.", '\n')
            print_fitness_population(input_sequence, children[1:min(end, 20)])
            print('\n')
        end

        # get list of the chromosome representations sorted by fitness
        if length(children) == 0
            append!(fitness_population, get_fitness_population(input_sequence, create_gap_population(gap_counts, len, init_pop_size), len, score_list))
        else
            # place the children into the next population set
            append!(fitness_population, children)
        end

        # make sure to keep it sorted so elitism and crossover works again
        # became unsorted when adding children back to fitness (even though children are sorted atm)
        sort!(fitness_population, by = x -> (x[1]), rev = true)

        if printout
            print("The new population after crossover and mutation, max 20", '\n')
            print_fitness_population(input_sequence, fitness_population[1:min(end, 20)])
            print('\n')
        end

        if generation_count % 100 == 0
            println(string(generation_count, ' ', fitness_population[1][1], " New children: ",  length(children)))
        end

        generation_count -= 1
    end

    #print_fitness_population(input_sequence, fitness_population[1:min(end, 20)])
    #print_fitness_population(input_sequence, fitness_population[1:1])

    open("out.txt", "w") do io
        open("out.txt", "w") do f  # "w" for writing
            write(f, print_fitness_population(input_sequence, fitness_population[1:1]))
        end
    end;

end

export MSA