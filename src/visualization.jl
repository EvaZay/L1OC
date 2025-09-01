"""
Построение энергетического спектра на графике
plot_spectrum(spectrum::Vector{<:Number}, freqs::LinRange{Float64, Int64})

spectrum -- энергетический спектр
freqs -- вектор частот
"""
function plot_spectrum(spectrum::Vector{<:Number}, freqs::LinRange{Float64, Int64})
    p = plot(freqs, spectrum,
            seriestype=:sticks,
            m=:dot,
            framestyle=:zerolines,
            title="Энергетический спектр сигнала ГЛОНАСС L10C",
            xlabel="Частота (МГц)",
            ylabel="Мощность (дБ)",
            grid=true,
            legend=false)
    return p
end

"""
Рассчет энергетического спектра
calculate_energy_spectrum(params::L1OCParameters, signal::Vector{Float64})

params -- параметры сигнала
signal -- сигнал L1OC
"""
function calculate_energy_spectrum(params::L1OCParameters, signal::Vector{Float64})
    fs = params.frequencies[:sampling]
    x_fft = fft(signal)
    x_fftshift = fftshift(x_fft)
    x_real = real.(x_fftshift)
    x_imag = imag.(x_fftshift)
    spectrum = x_real.^2 .+ x_imag.^2
    freqs = LinRange(0, fs/2, length(spectrum))

    return spectrum, freqs
end

"""
Рассчет актокорреляционной функции с помощью т.Винера-Хинчина
calculate_autocorrelation(signal::Vector{Float64})

signal -- сигнал L1OC
"""
function calculate_autocorrelation(signal::Vector{Float64})
    res = real.(ifft(abs2.(fft(signal))))

    return res
end

"""
Построение автокорреляционной функции на графике
plot_autocorrelation(signal::Vector{Float64})

signal -- сигнал L1OC
"""
function plot_autocorrelation(signal::Vector{Float64})
    cfx = calculate_autocorrelation(signal)

    plot(cfx, marker=:d, legend = false, title="Автокорреляционная функция", linecolor=:blue, seriestype=:sticks, m=:dot, framestyle=:zerolines, grid=true, xlims=(-0.5, length(signal)-0.5))
end