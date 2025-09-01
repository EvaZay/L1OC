using L1OC, Plots

parameters = L1OCParameters(
    16368e3, 
    4092e3, 
    2e-3, 
    0.0, 
    1, 
    14)

l1oc = generate_l1oc_signal(parameters)

spectrum, freqs = calculate_energy_spectrum(parameters, l1oc[1:30690])
pl1 = plot_spectrum(spectrum, freqs)
savefig(pl1, "results/spectrum.png")

pl2 = plot_autocorrelation(l1oc[1:30690])
savefig(pl2, "results/autocor.png")