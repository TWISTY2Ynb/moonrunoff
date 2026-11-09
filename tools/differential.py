"""Independent rational oracle; generated integer inputs, no upstream fixtures.
Run from repository root with MoonBit on PATH. Uses standard library only.
"""
import json, math, os, random, subprocess
from fractions import Fraction as Q
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
RNG = random.Random(20261109)

def execute(request):
    result = subprocess.run(['moon', 'run', 'cmd/moonrunoff', '--', '--request',
                             json.dumps(request, separators=(',', ':'))], cwd=ROOT,
                            capture_output=True, text=True, check=True)
    return json.loads(result.stdout)

def pattern(rows, average):
    factors = []
    for age in range(len(rows)-1):
        pairs = [(Q(r[age]), Q(r[age+1])) for r in rows if len(r)>age+1]
        if average == 'volume':
            f = sum(y for x,y in pairs) / sum(x for x,y in pairs)
        elif average == 'simple':
            f = sum(y/x for x,y in pairs) / len(pairs)
        else:
            f = sum(x*y for x,y in pairs) / sum(x*x for x,y in pairs)
        factors.append(f)
    cdf = [Q(11,10)]
    for f in reversed(factors):
        cdf.insert(0,cdf[0]*f)
    return list(reversed(cdf))  # origin i has age n-i-1

def expected(rows, cdfs, estimator, prior, exposure):
    latest = list(map(lambda r: Q(r[-1]), rows))
    if estimator == 'chain-ladder':
        return [x*f for x,f in zip(latest,cdfs)]
    if estimator == 'cape-cod':
        rate = sum(latest) / sum(Q(x)/f for x,f in zip(exposure,cdfs))
        current = [rate*x for x in exposure]
    else:
        current = list(map(Q,prior))
    for _ in range(3 if estimator=='benktander' else 1):
        current = [x+p*(1-1/f) for x,p,f in zip(latest,current,cdfs)]
    return current

def main():
    cases = cells = 0
    maximum = 0.0
    for _ in range(12):
        n = RNG.randint(2,9)
        rows = []
        for i in range(n):
            row=[]; total=0
            for age in range(n-i):
                total += RNG.randint(1,1000)
                row.append(total)
            rows.append(row)
        prior = [RNG.randint(500,5000) for _ in rows]
        exposure = [RNG.randint(1000,10000) for _ in rows]
        for average in ['volume','simple','regression']:
            cdfs = pattern(rows,average)
            for estimator in ['chain-ladder','bornhuetter-ferguson','benktander','cape-cod']:
                req = dict(triangle=rows,average=average,tail=1.1,estimator=estimator)
                if estimator in ['bornhuetter-ferguson','benktander']: req['prior']=prior
                if estimator=='benktander': req['iterations']=3
                if estimator=='cape-cod': req['exposure']=exposure
                got = execute(req)
                want = expected(rows,cdfs,estimator,prior,exposure)
                for origin, value in zip(got['origins'], want):
                    relative = abs(origin['ultimate']-float(value))/(1+abs(float(value)))
                    maximum=max(maximum,relative)
                    assert relative < 1e-10, (req,origin,value)
                    cells += 1
                payment_total = sum(p['amount'] for p in got['payments'])
                assert math.isclose(payment_total,got['total_reserve'],abs_tol=1e-8,rel_tol=1e-10)
                cases += 1
    print(json.dumps(dict(cases=cases,origin_comparisons=cells,max_relative_error=maximum,seed=20261109)))

if __name__=='__main__': main()
