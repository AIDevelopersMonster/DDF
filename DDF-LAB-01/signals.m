% DDF-LAB-01: Moving Average
% System-level functional verification

n = 0:127;
x = round(2048 + 600*sin(2*pi*n/32) + 220*(-1).^n);

data = [n(:), x(:)];

for N = [4 8 16]

    % Model A: direct FIR
    direct = filter(ones(1,N)/N, 1, x);

    % Model B: running sum
    acc = 0;
    recursive = zeros(size(x));

    for k = 1:length(x)
        acc = acc + x(k);

        if k > N
            acc = acc - x(k-N);
        end

        recursive(k) = acc/N;
    end

    err = max(abs(direct - recursive));
    assert(err < 1e-9);

    printf("N=%d | error=%g | PASS\n", N, err);

    data = [data, direct(:)];
end

csvwrite("signals.csv", data);

disp("DDF-LAB-01: ALL TESTS PASSED");
disp("CSV READY: signals.csv");
