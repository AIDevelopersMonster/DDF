% DDF-LAB-01
% System-level modeling of a moving average filter
% GNU Octave 11.3.0

clear;
close all;
clc;

rng(42);

% Simulated 12-bit ADC signal
n = 0:199;

x = 2048 + 900*sin(2*pi*n/50) ...
         + 300*randn(size(n));

x = round(x);
x = max(0, min(4095, x));

% Filter window sizes
Ns = [4, 8, 16];
Y = zeros(length(Ns), length(x));

fprintf("DDF-LAB-01: Moving Average\n");
fprintf("Input: 12-bit ADC, 200 samples\n\n");

for j = 1:length(Ns)

    N = Ns(j);

    % Architecture A: direct FIR
    h = ones(1,N)/N;
    direct = filter(h,1,x);

    % Architecture B: running sum
    recursive = zeros(size(x));
    acc = 0;

    for k = 1:length(x)

        acc = acc + x(k);

        if k > N
            acc = acc - x(k-N);
        end

        recursive(k) = acc/N;
    end

    % Equivalence verification
    err = max(abs(direct-recursive));

    assert(err < 1e-9);

    Y(j,:) = direct;

    bits = 12 + ceil(log2(N));
    variation = mean(abs(diff(direct)));

    fprintf("N=%d | error=%g | sum=%d bits", ...
            N, err, bits);
    fprintf(" | mean step=%.2f | PASS\n", ...
            variation);
end

fprintf("\nInput mean step: %.2f\n", ...
        mean(abs(diff(x))));

% Plot input and filtered signals
figure("visible","off", ...
       "position",[50 50 1100 600]);

plot(n,x,":","linewidth",1);
hold on;

plot(n,Y(1,:),"linewidth",1.5);
plot(n,Y(2,:),"linewidth",1.8);
plot(n,Y(3,:),"linewidth",2);

grid on;
xlabel("Sample number");
ylabel("ADC value");

title("DDF-LAB-01: Moving Average Filter");

legend("Input","N=4","N=8","N=16");

print("DDF-LAB-01_signals.png", ...
      "-dpng","-r150");

close all;

fprintf("\nDDF-LAB-01: ALL TESTS PASSED\n");
fprintf("Graph: DDF-LAB-01_signals.png\n");
