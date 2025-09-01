"""
Генерация оверлейного кода
generate_overlay_code(params::L1OCParameters)::BitVector

params -- Экземпляр структуры, хранящей параметры ГЛОНАСС из ИКД и условия задачи
"""
function generate_overlay_code(params::L1OCParameters)::BitVector
    n = Int(params.times[:moduling] / params.periods[:overlay_code])
    return [(iseven(i)) for i in 1:n*2]
end
"""
Генерация меандровой последовательности
generate_meander_sequence(params::L1OCParameters)::BitVector

params -- Экземпляр структуры, хранящей параметры ГЛОНАСС из ИКД и условия задачи
"""
function generate_meander_sequence(params::L1OCParameters)::BitVector
    return [(iseven(i)) for i in 1:Int(params.frequencies[:meander] * params.times[:moduling])]
end
"""
Генерация циклического кодера
generate_circular_code!(params::L1OCParameters, input_bits::BitVector)

params -- Экземпляр структуры, хранящей параметры ГЛОНАСС из ИКД и условия задачи
input_bits -- Вектор, хранящий информацию о ЦИ
"""
function generate_circular_code!(params::L1OCParameters, input_bits::BitVector)
    params.register_circ_code = falses(16)

    for i in 1:234
        feedback = xor(
            params.register_circ_code[1], 
            params.register_circ_code[5], 
            params.register_circ_code[6], 
            params.register_circ_code[8], 
            params.register_circ_code[9], 
            params.register_circ_code[10], 
            params.register_circ_code[11], 
            params.register_circ_code[13], 
            params.register_circ_code[14], 
            input_bits[i]
            )

        for j in length(params.register_circ_code)-1:-1:1
            params.register_circ_code[j+1] = params.register_circ_code[j]
        end

        params.register_circ_code[1] = feedback
    end

    for i in 235:250
        input_bits[i] = params.register_circ_code[end]

        for j in length(params.register_circ_code)-1:-1:1
            params.register_circ_code[j+1] = params.register_circ_code[j]
        end

        params.register_circ_code[1] = 0
    end
end
"""
Генерация ЦИ 
generate_digital_information(params::L1OCParameters)::BitVector

params -- Экземпляр структуры, хранящей параметры ГЛОНАСС из ИКД и условия задачи
"""
function generate_digital_information(params::L1OCParameters)::BitVector
    digital_information = BitVector(i % 2 for i in 1:250)

    for i in 1:12
        digital_information[i] = params.timestamp_signal[i]
    end
    for i in 19:24
        digital_information[i] = params.j[i-18]
    end
    for i in 35:50
        digital_information[i] = params.time_start[i-34]
    end

    generate_circular_code!(params, digital_information)

    return digital_information
end
"""
Генерация дальномерного кода для data-компоненты
genereate_dk_data(params::L1OCParameters)::BitVector

params -- Экземпляр структуры, хранящей параметры ГЛОНАСС из ИКД и условия задачи
"""
function genereate_dk_data(params::L1OCParameters)::BitVector
    n_periods_data = params.times[:moduling] / params.periods[:data]
    dk_data = falses(Int(params.n_data * n_periods_data))
    for i in eachindex(dk_data)
        dk_data[i] = xor(params.register_data_1[end], params.register_data_2[end])

        feedback1 = xor(params.register_data_1[7], params.register_data_1[10])
        feedback2 = xor(params.register_data_2[3], params.register_data_2[7], params.register_data_2[9], params.register_data_2[10])
        for j in length(params.register_data_1)-1:-1:1
            params.register_data_1[j+1] = params.register_data_1[j]
            params.register_data_2[j+1] = params.register_data_2[j]
        end

        params.register_data_1[1], params.register_data_2[1] = feedback1, feedback2

        if i % params.n_data == 0
            params.register_data_1 .= params.ic_data_1
            params.register_data_2 .= params.ic_data_2
        end
    end
    return dk_data
end
"""
Генерация дальномерного кода для pilot-компоненты
genereate_dk_pilot(params::L1OCParameters)::BitVector

params -- Экземпляр структуры, хранящей параметры ГЛОНАСС из ИКД и условия задачи
"""
function genereate_dk_pilot(params::L1OCParameters)::BitVector
    n_periods_pilot = params.times[:moduling] / params.periods[:pilot]
    dk_pilot = falses(Int(params.n_pilot * n_periods_pilot))
    for i in eachindex(dk_pilot)
        dk_pilot[i] = xor(params.register_pilot_1[end], params.register_pilot_2[end])

        feedback1 = xor(params.register_pilot_1[6], params.register_pilot_1[8], params.register_pilot_1[11], params.register_pilot_1[12])
        feedback2 = xor(params.register_pilot_2[1], params.register_pilot_2[6])
        for j in 11:-1:1
            params.register_pilot_1[j+1] = params.register_pilot_1[j]
        end
        for j in 5:-1:1
            params.register_pilot_2[j+1] = params.register_pilot_2[j]
        end

        params.register_pilot_1[1], params.register_pilot_2[1] = feedback1, feedback2

        if i % params.n_pilot == 0
            params.register_pilot_1 .= params.ic_pilot_1
            params.register_pilot_2 .= params.ic_pilot_2
        end
    end
    return dk_pilot
end
"""
Генерация сверточного кодера (133, 171)
convolutional_encoder(params::L1OCParameters, digital_information::BitVector)::BitVector

params -- Экземпляр структуры, хранящей параметры ГЛОНАСС из ИКД и условия задачи
digital_information -- цифровая информация(ЦИ)
"""
function convolutional_encoder(params::L1OCParameters, digital_information::BitVector)::BitVector
    convolution_code = falses(length(digital_information) * 2)
    for i in eachindex(digital_information)
        out_1 = xor(
            digital_information[i], 
            params.register_convolution[1], 
            params.register_convolution[2], 
            params.register_convolution[3], 
            params.register_convolution[6]
            )
        out_2 = xor(
            digital_information[i], 
            params.register_convolution[2], 
            params.register_convolution[3], 
            params.register_convolution[5], 
            params.register_convolution[6]
            )

        for j in length(params.register_convolution)-1:-1:1
            params.register_convolution[j+1] = params.register_convolution[j]
        end

        params.register_convolution[1] = digital_information[i]
        convolution_code[i*2-1], convolution_code[i*2] = out_1, out_2
    end
    return convolution_code
end