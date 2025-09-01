const QPKS_CONSTELLATION = Dict(
        (0, 0) => complex(1.0/sqrt(2), 1.0/sqrt(2)),
        (0, 1) => complex(-1.0/sqrt(2), 1.0/sqrt(2)),
        (1, 1) => complex(-1.0/sqrt(2), -1.0/sqrt(2)), 
        (1, 0) => complex(1.0/sqrt(2), -1.0/sqrt(2))
    )


"""
BPSK - модулятор
bpsk_modulator(input_symbol::Bool)

input_symbol -- последовательность сигнала data-компоненты для модуляции (П_L1OCd)
"""
bpsk_modulator(input_symbol::Bool)::Int8 = input_symbol ? input_symbol : -1

"""
BOC(1, 1) - модулятор
boc_1_1_modulator(params::L1OCParameters, input_sequence::BitVector)::Vector{Int8}

params -- параметры сигнала из ИКД
input_sequence -- последовательность сигнала pilot-компоненты для модуляции (П_L1OCp)
"""
function boc_1_1_modulator(params::L1OCParameters, input_sequence::BitVector)::Vector{Int8}
    time_moduling = params.times[:moduling]
    freq_boc = params.frequencies[:meander]
    t = LinRange(0, time_moduling, Int(time_moduling * freq_boc))
    return Int8.(sign.(sin.(2pi * freq_boc * t))) .* input_sequence
end

"""
Квадратурный модулятор
qpsk_modulator(params::L1OCParameters, input_sequence::Vector{Int8})::Vector{Float64}

params -- параметры сигнала из ИКД
input_sequence -- последовательность П_L1OC
"""
function qpsk_modulator(params::L1OCParameters, input_sequence::Vector{Int8})::Vector{Float64}
    t = LinRange(0.0, length(input_sequence) / 1600.995e6, length(input_sequence))

    return -input_sequence .* sin.(2pi * params.frequencies[:sampling] * t)
end
"""
Реализация ПВУ
chip_time_compaction(params::L1OCParameters, p_l1oc_d::BitVector, p_l1oc_p::BitVector)::Vector{Int8}

params -- параметры из ИКД
p_l1oc_d -- последовательность П_L1OCd
p_l1oc_p -- последовательность П_L1OCp
"""
function chip_time_compaction(params::L1OCParameters, p_l1oc_d::BitVector, p_l1oc_p::BitVector)::Vector{Int8}
    p_l1oc_d = bpsk_modulator.(p_l1oc_d)
    p_l1oc_p = boc_1_1_modulator(params, p_l1oc_p)

    p_l1oc = zeros(Int8, length(p_l1oc_d) + Int(length(p_l1oc_p) / 2))
    data_idx = 1
    pilot_idx = 1
    idx = 1
    for _ in eachindex(p_l1oc_d)
        p_l1oc[idx] = p_l1oc_d[data_idx]
        idx += 1
        data_idx += 1
        pilot_idx += 2
        for j in 1:2
            p_l1oc[idx] = p_l1oc_p[pilot_idx]
            idx += 1
            pilot_idx += 1
        end
    end
    return p_l1oc
end