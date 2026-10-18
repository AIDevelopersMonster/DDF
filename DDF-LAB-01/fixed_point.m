% DDF-LAB-01: Fixed-width arithmetic model

clear;
clc;
rng(42);

% 12-bit unsigned ADC test sequence
x = [zeros(1,8), ...
     4095*ones(1,24), ...
     zeros(1,8), ...
     repmat([0 4095],1,24), ...
     randi([0 4095],1,512)];

for N = [4 5]

    % Reference model: direct FIR
    sums = filter(ones(1,N),1,x);
    reference = floor(sums/N);

    % Architecture B: running sum
    history = zeros(1,N);
    acc = 0;
    result = zeros(size(x));

    for k = 1:numel(x)

        idx = mod(k-1,N)+1;

        old = history(idx);

        % Subtract old sample before adding new
        acc = acc - old + x(k);

        history(idx) = x(k);

        assert(acc >= 0);
        assert(acc <= N*4095);

        result(k) = floor(acc/N);
    end

    assert(isequal(reference,result));

    bits = ceil(log2(N*4095+1));

    printf("N=%d | accumulator=%d bits",N,bits);
    printf(" | max_sum=%d | PASS\n",max(sums));

end

disp("DDF-LAB-01: INTEGER MODEL PASS");
