"""Optional independent comparison against chainladder 0.8.24.
Self-generated data only; no upstream code or fixtures are copied.
Install tools/reference-requirements.txt in a separate Python 3.12 environment.
Scope: positive annual triangles, all three averages, four deterministic models,
no tail, no pair exclusions, no calendar trend. See differential.py for tails.
"""
import json
import random
import warnings
import chainladder as cl
import numpy as np
import pandas as pd
from differential import execute


def main():
    assert cl.__version__ == '0.8.24', cl.__version__
    rng = random.Random(20261111)
    cases = comparisons = 0
    maximum = 0.0
    for case in range(6):
        n = rng.randint(3, 7)
        rows = []
        for i in range(n):
            row = []
            total = 0
            for j in range(n-i):
                total += rng.randint(10, 900)
                row.append(total)
            rows.append(row)
        frame = pd.DataFrame([
            dict(origin=str(2000+i), development=str(2000+i+j), paid=value)
            for i, row in enumerate(rows) for j, value in enumerate(row)
        ])
        triangle = cl.Triangle(frame, origin='origin', development='development',
                               columns='paid', cumulative=True)
        prior = [rng.randint(500, 5000) for _ in rows]
        exposure = [rng.randint(1000, 10000) for _ in rows]
        for average in ['volume', 'simple', 'regression']:
            fitted = cl.Development(average=average).fit_transform(triangle)
            for estimator in ['chain-ladder', 'bornhuetter-ferguson', 'benktander', 'cape-cod']:
                request = dict(triangle=rows, average=average, estimator=estimator)
                if estimator == 'chain-ladder':
                    model = cl.Chainladder().fit(fitted)
                else:
                    weights = triangle.latest_diagonal.copy()
                    values = exposure if estimator == 'cape-cod' else prior
                    weights.values = np.array(values, dtype=float).reshape(weights.shape)
                    if estimator == 'bornhuetter-ferguson':
                        request['prior'] = prior
                        model = cl.BornhuetterFerguson().fit(fitted, sample_weight=weights)
                    elif estimator == 'benktander':
                        request.update(prior=prior, iterations=3)
                        model = cl.Benktander(n_iters=3).fit(fitted, sample_weight=weights)
                    else:
                        request['exposure'] = exposure
                        model = cl.CapeCod(trend=0, decay=1).fit(fitted, sample_weight=weights)
                expected = model.ultimate_.values.reshape(-1)
                got = execute(request)
                assert len(expected) == len(got['origins']) == n
                for origin, value in zip(got['origins'], expected):
                    assert np.isfinite(value)
                    relative = abs(origin['ultimate']-value)/(1+abs(value))
                    maximum = max(maximum, float(relative))
                    assert relative < 1e-10, (case, average, estimator, origin, float(value))
                    comparisons += 1
                cases += 1
    print(json.dumps(dict(reference='chainladder', version=cl.__version__, seed=20261111,
                         cases=cases, origin_comparisons=comparisons,
                         max_relative_error=maximum, tolerance=1e-10,
                         scope='positive annual triangles; three averages; four models; tail=1')))


if __name__ == '__main__':
    main()