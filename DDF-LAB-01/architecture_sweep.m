% DDF-LAB-01: Architecture Design Space Exploration

clear;
clc;
rng(42);

noise = 220*randn(1,4096);

fprintf("DDF-LAB-01: Architecture candidates\n");

for N = 2:16

    h = ones(1,N)/N;
    yn = filter(h,1,noise);

    ratio = std(yn(33:end)) / std(noise(33:end));

    gain = abs(sin(pi*N/32)/(N*sin(pi/32)));
    delay = (N-1)/2;

    bits = 12 + ceil(log2(N));

    accepted = gain >= 0.95 ...
            && ratio <= 0.55 ...
            && delay <= 2;

    if accepted
        printf("N=%d gain=%.4f noise=%.3f delay=%.1f bits=%d ACCEPT\n", ...
               N,gain,ratio,delay,bits);
    end
end
