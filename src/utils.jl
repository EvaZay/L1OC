const EXPECTED_FIRST_DK_DATA = BitVector([0, 1, 1, 0, 0, 0, 1, 1, 0, 0, 1, 0, 0, 1, 1, 0, 0, 0, 0, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 1, 1, 0])
const EXPECTED_LAST_DK_DATA = BitVector([0, 1, 0, 0, 1, 1, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1, 1, 1, 1, 1, 0, 1])
const EXPECTED_FIRST_DK_PILOT = BitVector([1, 1, 0, 1, 0, 0, 1, 0, 0, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 1])
const EXPECTED_LAST_DK_PILOT = BitVector([1, 1, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0])

"""
Метод преобразования числа в вектор битов с заданной длиной
integer_to_bit_vector(value::Integer, n::Integer)::BitVector

value -- число, которое необходимо преобразовать в вектор битов
n -- длина вектора битов
"""
function integer_to_bit_vector(value::Integer, n::Integer)::BitVector
    bit_vector = falses(n)
    for i in n:-1:1
        bit_vector[i] = value & UInt8(1)
        value >>= 1
    end
    return bit_vector
end

"""
Проверка на первые и последние 32 битов последовательности дальномерных кодов для data- и pilot- компоненты
test_dks(dk_data::BitVector, dk_pilot::BitVector)

dk_data -- дальномерный код для data-компоненты
dk_pilot -- дальномерный код для pilot-компоненты
"""
function test_dks(dk_data::BitVector, dk_pilot::BitVector)
    dk_data[1:32] == EXPECTED_FIRST_DK_DATA || throw("Неверные дальномерные коды data-составляющей сигнала")
    dk_pilot[1:32] == EXPECTED_FIRST_DK_PILOT || throw("Неверные дальномерные коды pilot-составляющей сигнала")
    dk_data[end-31:end] == EXPECTED_LAST_DK_DATA || throw("Неверные дальномерные коды data-составляющей сигнала")
    dk_pilot[end-31:end] == EXPECTED_LAST_DK_PILOT || throw("Неверные дальномерные коды pilot-составляющей сигнала")

    return 
end