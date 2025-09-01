module L1OC

using FFTW, DSP, Plots

export L1OCParameters, generate_l1oc_signal, calculate_energy_spectrum, plot_spectrum, plot_autocorrelation
"""
Параметры из ИКД и условия задачи

    Поля структуры:
    periods -- именнованный кортеж всех периодов для построения сигнала
    frequencies -- именнованный кортеж всех частот для построения сигнала
    times -- именнованный кортеж времени модуляции
    n_data -- количество символов в коде Голда (для data-компоненты)
    n_pilot -- количество символов в коде Касами (для pilot-компоненты)
    ic_data_1 -- код НС1 для построения дальномерного кода data-компоненты
    ic_data_2 -- код НС2 для построения дальномерного кода data-компоненты
    ic_pilot_1 -- код НС1 для построения дальномерного кода pilot-компоненты
    ic_pilot_2 -- код НС1 для построения дальномерного кода pilot-компоненты
    register_data_1 -- сдвиговый регистр в ЦА1 для ДК data-компоненты
    register_data_2 -- сдвиговый регистр в ЦА2 для ДК data-компоненты
    register_pilot_1 -- сдвиговый регистр в ЦА1 для ДК pilot-компоненты
    register_pilot_2 -- сдвиговый регистр в ЦА2 для ДК pilot-компоненты
    register_circ_code -- сдвиговый регистр для циклического кода
    register_convolution -- сдвиговый регистр для сверточного кодера
    timestamp_signal -- сигнал метки времени(константа по ИКД)
    j -- номер НКА, передающего информацию
    time_start -- начало сообщения по ШВС

    Конструктор параметров для сигнла L1OC
    L1OCParameters(sampling_frequency::Real, intermidiate_frequency::Real, 
        time_modeling::Real, time_start::Real, A::Real, NKA::Integer)

        sampling_frequency -- частота дискретизации
        intermidiate_frequency -- промежуточная частота
        time_modeling -- длительность выборки моделируемого сигнла
        time_start -- время начала сообщения по ШВС
        A -- амплитуда каждой компоненты
        NKA -- номер НКА, передающего навигационное сообщение

"""
mutable struct L1OCParameters{PerType, FreqType, TimeType}
    periods::PerType
    frequencies::FreqType
    times::TimeType
    n_data::Int64
    n_pilot::Int64
    ic_data_1::BitVector
    ic_data_2::BitVector
    ic_pilot_1::BitVector
    ic_pilot_2::BitVector
    register_data_1::BitVector
    register_data_2::BitVector
    register_pilot_1::BitVector
    register_pilot_2::BitVector
    register_circ_code::BitVector
    register_convolution::BitVector
    timestamp_signal::BitVector
    j::BitVector
    time_start::BitVector

    function L1OCParameters(sampling_frequency::Real, intermidiate_frequency::Real, 
        time_modeling::Real, time_start::Real, A::Real, NKA::Integer)

        n_data = 1023
        n_pilot = 4092

        T_data = 2e-3
        T_pilot = 8e-3
        T_ok = 4e-3
        periods = (data = T_data, pilot = T_pilot, overlay_code = T_ok)

        freq_t1 = 1023e3
        freq_data = freq_t1 / 2
        freq_pilot = freq_t1 / 2
        freq_meander = freq_t1 * 2
        frequencies = (t1 = freq_t1, data = freq_data, pilot = freq_pilot, meander = freq_meander, 
            sampling = sampling_frequency, intermidiate = intermidiate_frequency)

        time_moduling = 2
        time_grid_boc = LinRange(0, time_moduling, Int(time_moduling * freq_meander))
        time_grid_qpsk = LinRange(0, time_moduling, Int(time_moduling * sampling_frequency))
        times = (modeling = time_modeling, moduling = time_moduling, grid_boc = time_grid_boc, grid_qpsk = time_grid_qpsk)
        
        ic_data_1 = [0, 0, 1, 1, 0, 0, 1, 0, 0, 0]
        ic_data_2 = [0, 0, 0, 0, 0, 0, 1, 1, 1, 0]
        ic_pilot_1 = [0, 0, 0, 0, 1, 1, 0, 0, 0, 1, 0, 1]
        ic_pilot_2 = [0, 0, 1, 1, 1, 0]

        n_periods_data = time_moduling / T_data
        n_periods_pilot = time_moduling / T_pilot

        timestamp_signal = BitVector([0, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0, 1])
        j = integer_to_bit_vector(NKA, 6)
        time_start = integer_to_bit_vector(Int(time_start), 16)

        return new{typeof(periods), typeof(frequencies), typeof(times)}(
            periods, frequencies, times, n_data, n_pilot, 
            ic_data_1, ic_data_2, ic_pilot_1, ic_pilot_2, 
            deepcopy(ic_data_1), deepcopy(ic_data_2), 
            deepcopy(ic_pilot_1), deepcopy(ic_pilot_2),
            falses(16), falses(6), 
            timestamp_signal, j, time_start)
    end
end

"""
Генерация сигнала L1OC
generate_l1oc_signal(parameters::L1OCParameters)::Vector{Float64}

parameters -- параметры сигнала L1OC
"""
function generate_l1oc_signal(parameters::L1OCParameters)::Vector{Float64}
    dk_data = genereate_dk_data(parameters)
    dk_pilot = genereate_dk_pilot(parameters)
    test_dks(dk_data, dk_pilot)

    digital_information = generate_digital_information(parameters)
    convolution_code = convolutional_encoder(parameters, digital_information)
    overlay_code = generate_overlay_code(parameters)
    meander_sequence = generate_meander_sequence(parameters)

    p_l1oc_d = synchronization_two_sequenses(synchronization_two_sequenses(convolution_code, overlay_code), dk_data)
    p_l1oc_p = synchronization_two_sequenses(dk_data, meander_sequence)

    p_l1oc = chip_time_compaction(parameters, p_l1oc_d, p_l1oc_p)
    pl4 = plot_autocorrelation(float.(p_l1oc[1:30690]))
    savefig(pl4, "results/autocor_seq.png")
    l1oc = qpsk_modulator(parameters, p_l1oc)
end

include("generators.jl")
include("modulators.jl")
include("synchronizers.jl")
include("visualization.jl")
include("utils.jl")

end # module L1OC
