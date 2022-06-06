using XLSX
using FFTW
using Plots

xf = XLSX.readxlsx("data.xlsx")
sh = xf["Sheet1"]
data = sh["A2:C602"]

frequency = 1/0.005
# we dont need these 2 because we know that the frequency is 200hz
# index = data[:,:1]
# time = data[:,:2]
signal_v = data[:,:3]

signal = Array{Float64,1}(undef, 0)
for value in signal_v
    push!(signal, value)
end

# plots the fourier transfrom of the given signal
function fourier_transfrom(signal)
    global frequency    
    F = fftshift(fft(signal))
    freqs = fftshift(fftfreq(length(signal), frequency))
    plot(freqs, abs.(F), xlim=(0,100))
end

fourier_transfrom(signal)

# DSP course Lecture 11
# creates a low pass FIR filter
function create_low_pass(Wco, n)
    h = []
    v = Float64
    for i in -n:(n+1)
        if i == 0
            v=Wco/pi
        else
            v=sin(Wco*i) / (i*pi)
        end
        push!(h, v)
    end
    return h
end

# also from lecture 11 DSP
function H_ejW(W,b)
    Nb = length(b)
    sum = 0
    for k in 1:Nb
        sum += b[k]*exp(complex(0,-W*k))
    end
    return sum
end

# also from DSP lecture 11
function frequency_response(Wco, M)
    N=2*M+1
    b = create_low_pass(Wco, M)

    W = (-pi+0.0001):0.001:pi
    n = length(W)
    mag = []
    phase = []
    for i in 1:n 
        h=H_ejW(W[i],b)
        # push!(mag, real(h))
        push!(mag, abs(h))
        push!(phase, angle(h))
    end
    return (W,mag,phase)
end

# creating a low pass filter with a cutoff of 25 hz
filter = create_low_pass(1/4*pi, 20)

output = Array{Float64,1}(undef, 0)

# applies the FIR filter to the signal
for k in 1:(length(signal)-length(filter))
    temp_output = 0
    for i in 1:length(filter)
        temp_output += signal[k+i]*filter[i]
    end
    push!(output, temp_output)
end

# plotting the Fourier transform of both the original signal and the filtered signal

fourier_transfrom(signal)
fourier_transfrom(output)

# plotting mag and phase

freq = frequency_response((1/4)*pi, 21)
W = freq[1]
mag = freq[2]
phase = freq[3]
W = (W / pi) * 100

plot(W,mag, label="Magnitude", xlabel="Frequency")
plot!(W,phase, label="Phase")
