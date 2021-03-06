# insert at the given index, "123" inserted '_' at 2 would end up "1_23"
function insert_char(og_string, index, character)
    return string(og_string[1:index - 1], character, og_string[index:length(og_string)])
end

# if given an input sequence and a corresponding chromosome representation
# rebuild the string by inserting gaps into the gap positions labeled in the chrom_rep
function build_strings(input_sequence, chrom_rep)
    full_str = []
    for i = 1:length(input_sequence)
        my_string = input_sequence[i]
        
        for j = 1:length(chrom_rep[i])
           my_string = insert_char(my_string, chrom_rep[i][j], '_')
        end
        push!(full_str, my_string)
    end
    
    return full_str
end

# take the input sequence and growth fraction and calculate the extension to the longest string in the sequence
# then create a list of the number of gaps needed to reach that length for each string in the sequence
# return gap list and length
function get_gap_count(input_sequence, growth)

    # set our max to negative, will be overwritten by a length, which is always positive
    mx = -1

    # store the lengths of each sequence to determine number of gaps later
    gap_counts = []

    # go through each input sequence and overwrite mx if the length is larger than what we have seen already
    for i = 1:length(input_sequence)
        # put the length of each sequence into gap counts to be updated once we know the final length
        push!(gap_counts, length(input_sequence[i]))
        mx = max(mx, length(input_sequence[i]))
    end
    
    # this length will be what we put the actual size of all of our strings to, including the gaps
    len = ceil(growth * mx)

    # change the lengths to be the number of gaps needed to reach the calculated length
    for i = 1:length(gap_counts)
        gap_counts[i] = Int(len - gap_counts[i])
    end

    # return gap count for each string needed to extend it to calculated length
    return gap_counts, Int(len)
end

function msa_from_file(file)
    score_list = []
    input_sequence = []
    open(file, "r") do io
        lines = readlines(io)
        push!(score_list, parse(Int64, lines[1]))
        push!(score_list, parse(Int64, lines[2]))
        push!(score_list, parse(Int64, lines[3]))

        range = 4 + parse(Int64, lines[4]) * 2
        for i = 5:2:range
            push!(input_sequence, [lines[i], lines[i + 1]])
        end
    end;

    println(score_list)
    println(input_sequence)

    return score_list, input_sequence
end

function pairwise_score(reference_sequence, input_sequence)
    sequence_length = length(reference_sequence[1])
    score = 0

    match = 0
    mismatch = 0
    total = 0

    ref_list = []
    index_list = fill(1, length(reference_sequence))

    # for every sequence but the last
    for i = 1:length(reference_sequence) - 1
        # go through all characters (columns)
        for pos = 1:sequence_length
            # only check the characters
            if reference_sequence[i][pos] == '_'
                continue
            end

            for j = i + 1:length(reference_sequence)
                if reference_sequence[j][pos] == '_'
                    continue
                end

                count = 0
                for k = 1:pos
                    if reference_sequence[j][k] == '_'
                        continue
                    end

                    count += 1
                end

                push!(ref_list, [ [i, index_list[i]], [j, count] ])
                total += 1
            end

            index_list[i] += 1
        end
    end

    ref_list2 = []
    index_list2 = fill(1, length(input_sequence))

    # for every sequence but the last
    for i = 1:length(input_sequence) - 1
        # go through all characters (columns)
        for pos = 1:sequence_length
            # only check the characters
            if input_sequence[i][pos] == '_'
                continue
            end

            for j = i + 1:length(input_sequence)
                if input_sequence[j][pos] == '_'
                    continue
                end

                count = 0
                for k = 1:pos
                    if input_sequence[j][k] == '_'
                        continue
                    end

                    count += 1
                end

                push!(ref_list2, [ [i, index_list2[i]], [j, count] ])
                total += 1
            end

            index_list2[i] += 1
        end
    end

    for i = 1:length(ref_list)
        if ref_list[i] in ref_list2
            println(ref_list[i])
            match += 1
        end
    end

    score = (match) / total

    #println(ref_list)
    println(score)

    return score
end

export insert_char
export build_strings
export get_gap_count
export msa_from_file
export pairwise_score