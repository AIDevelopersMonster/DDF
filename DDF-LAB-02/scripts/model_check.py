"""A numeric model check only. DOES NOT simulate Verilog source."""
from random import Random


def reference(samples):
    return [sum(samples[max(0,i-3):i+1])//4 for i in range(len(samples))]


def running_sum(samples):
    history=[]
    s=0
    y=[]
    for x in samples:
        if len(history)==4:
            s-=history.pop(0)
        history.append(x)
        s+=x
        assert 0<=s<=16380
        y.append(s//4)
    return y


def main():
    tests = [
        [4,0,0,0,0],
        [4095]*8,
        [0,4095]*50,
        [4095,0,1,2,3,4,4095],
        [],
    ]
    # Ensure pseudo-random sequence is varied and has a fixed seed.
    rng=Random(42)
    tests[-1]=[rng.randrange(4096) for _ in range(1024)]
    for seq in tests:
        assert reference(seq)==running_sum(seq)
    assert reference([4,0,0,0,0])==[1,1,1,1,0]
    assert reference([4095]*8)[-1]==4095
    print('MODEL_PASS: Python math/reference checks (not HDL simulation)')

if __name__=='__main__': main()
