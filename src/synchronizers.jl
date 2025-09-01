"""
Синхронизатор последовательностей
synchronization_two_sequenses(shorter_sequence::BitVector, larger_sequence::BitVector)::BitVector

shorter_sequence -- последовательность наименьшей длины
larger_sequence -- последовательность большей длины
"""
function synchronization_two_sequenses(shorter_sequence::BitVector, larger_sequence::BitVector)::BitVector
    synchonized_sequence = falses(length(larger_sequence))

    n = Int(length(larger_sequence) / length(shorter_sequence))

    for i in eachindex(larger_sequence)
        idx = mod(i, n) == 0 ? div(i, n) : div(i, n) + 1
        synchonized_sequence[i] = xor(larger_sequence[i], shorter_sequence[idx])
    end

    return synchonized_sequence
end