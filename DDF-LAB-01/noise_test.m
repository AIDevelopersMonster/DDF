% DDF-LAB-01: Noise reduction and requirements

clear;
clc;
rng(42);

n = 0:4095;
noise = 220*randn(size(n));

fprintf("DDF-LAB-01: Requirements verification\n");

for N = [4 8 16]

    h = ones(1,N)/N;
    filtered_noise = filter(h,1,noise);

    % Exclude the initial transient
    k = 33;

    noise_ratio = std(filtered_noise(k:end)) ...
                / std(noise(k:end));

    gain = abs(sin(pi*N/32) ...
           / (N*sin(pi/32)));

    delay = (N-1)/2;

    pass = gain >= 0.95 ...
        && noise_ratio <= 0.55 ...
        && delay <= 2;

    if pass
        result = "ACCEPT";
    else
        result = "REJECT";
    end

    printf("N=%d gain=%.4f noise=%.3f delay=%.1f %s\n", ...
           N,gain,noise_ratio,delay,result);
end
