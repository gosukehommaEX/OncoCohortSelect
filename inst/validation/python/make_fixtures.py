"""Expected values for the tests of OncoCohortSelect.

Run from the root of the package:

    python inst/validation/python/make_fixtures.py

The data sets and the expected values are written to tests/testthat/fixtures.
The expected values are computed with reference.py, independently of the R
code of the package.
"""

import csv
import math
import os
import sys

import numpy as np

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import reference as ref  # noqa: E402

OUT = os.path.join("tests", "testthat", "fixtures")
os.makedirs(OUT, exist_ok=True)


def write_csv(name, header, rows):
    with open(os.path.join(OUT, name), "w", newline="") as f:
        w = csv.writer(f, lineterminator="\n")
        w.writerow(header)
        for r in rows:
            w.writerow(["NA" if (isinstance(v, float) and math.isnan(v)) else v for v in r])


def fmt(x):
    return float("%.15g" % x)


# ---------------------------------------------------------------------------
# 1. Posterior probabilities
# ---------------------------------------------------------------------------
# measure, a, b, a_ref, b_ref, target, time, higher
cases = [
    ("rate", 26.5, 14.5, None, None, 0.50, None, True),
    ("rate", 9.5, 31.5, None, None, 0.30, None, False),
    ("rate", 0.5, 40.5, None, None, 0.05, None, False),
    ("rate", 1.0, 1.0, None, None, 0.20, None, True),
    ("surv", 12.5, 300.0, None, None, 0.80, 6.0, True),
    ("surv", 20.5, 250.0, None, None, 0.50, 12.0, True),
    ("surv", 3.5, 100.0, None, None, 0.90, 6.0, False),
    ("rate", 0.5, 50.5, 0.5, 45.5, 0.00, None, True),
    ("rate", 26.5, 14.5, 23.5, 17.5, 0.10, None, True),
    ("rate", 2.5, 38.5, 9.5, 31.5, 0.05, None, False),
    ("rate", 500.5, 500.5, 5.5, 5.5, 0.00, None, True),
    ("rate", 5.5, 5.5, 500.5, 500.5, 0.20, None, True),
    ("rate", 0.5, 0.5, 0.5, 0.5, -0.30, None, True),
    ("rate", 40.5, 0.5, 0.5, 40.5, 0.90, None, True),
    ("rate", 1.0, 1.0, 1.0, 1.0, 0.50, None, False),
    ("rate", 20.5, 20.5, 0.5, 40.5, 0.30, None, True),
    ("rate", 0.5, 0.5, 30.5, 10.5, -0.50, None, False),
    ("surv", 12.5, 300.0, 15.5, 280.0, 0.00, 6.0, True),
    ("surv", 0.5, 50.0, 0.5, 60.0, 0.10, 9.0, True),
    ("surv", 30.5, 400.0, 3.5, 40.0, -0.10, 12.0, True),
    ("surv", 300.5, 4000.0, 3.5, 40.0, 0.05, 6.0, False),
    ("surv", 3.5, 40.0, 300.5, 4000.0, 0.05, 6.0, True),
    ("surv", 5.5, 20.0, 8.5, 25.0, 0.30, 3.0, True),
    ("surv", 0.5, 5.0, 0.5, 400.0, -0.40, 6.0, False),
    ("surv", 2.5, 100.0, 20.5, 150.0, 0.20, 12.0, True),
    ("hr", 12.5, 300.0, 15.5, 280.0, 0.80, None, True),
    ("hr", 30.5, 400.0, 20.5, 200.0, 1.00, None, True),
    ("hr", 5.5, 20.0, 8.5, 25.0, 1.20, None, False),
    ("hr", 0.5, 10.0, 1.5, 30.0, 0.70, None, True),
]
rows = []
for i, (ms, a, b, ar, br, tg, tm, hi) in enumerate(cases, start=1):
    p = ref.posterior_prob(ms, a, b, tg, tm, ar, br, hi)
    rows.append([i, ms, a, b, "NA" if ar is None else ar, "NA" if br is None else br, tg,
                 "NA" if tm is None else tm, "TRUE" if hi else "FALSE", fmt(p)])
write_csv("posterior_expected.csv",
          ["case", "measure", "a", "b", "a_ref", "b_ref", "target", "time",
           "higher_better", "expected"], rows)

# ---------------------------------------------------------------------------
# 2. Generalized pairwise comparisons
# ---------------------------------------------------------------------------
EPS = {
    "os": dict(type="tte", time="os_time", event="os_event", higher=True),
    "pfs": dict(type="tte", time="pfs_time", event="pfs_event", higher=True),
    "resp": dict(type="binary", var="resp", higher=True),
    "ae": dict(type="binary", var="ae", higher=False),
}
for _name, _ep in EPS.items():
    _ep["name"] = _name


def make_patients(rng, n, arm, integer, na_resp):
    out = []
    for i in range(n):
        os_t = rng.exponential(14.0)
        pfs_t = min(os_t, rng.exponential(7.0))
        cens = rng.uniform(4.0, 24.0)
        if integer:
            os_t, pfs_t, cens = (float(math.ceil(v)) for v in (os_t, pfs_t, cens))
        pfs_t = min(pfs_t, os_t)
        resp = float(rng.uniform() < 0.4)
        if na_resp and i == 0:
            resp = float("nan")
        out.append(dict(arm=arm,
                        os_time=min(os_t, cens), os_event=int(os_t <= cens),
                        pfs_time=min(pfs_t, cens), pfs_event=int(pfs_t <= cens),
                        resp=resp, ae=float(rng.uniform() < 0.3)))
    return out


rng = np.random.RandomState(20261022)
datasets = {
    "ties": make_patients(rng, 12, "T", True, True) + make_patients(rng, 10, "C", True, True),
    "cont": make_patients(rng, 40, "T", False, False) + make_patients(rng, 35, "C", False, False),
}
for name, rows_d in datasets.items():
    if name == "cont":
        for r in rows_d:
            r["os_time"] = round(r["os_time"], 6)
            r["pfs_time"] = round(min(r["pfs_time"], r["os_time"]), 6)
    write_csv("gpc_%s.csv" % name, ["arm", "os_time", "os_event", "pfs_time", "pfs_event", "resp", "ae"],
              [[r["arm"], r["os_time"], r["os_event"], r["pfs_time"], r["pfs_event"],
                r["resp"], int(r["ae"])] for r in rows_d])

specs = {
    "spec1": (["os", "pfs", "resp", "ae"], [0, 0, 0, 0]),
    "spec2": (["resp", "pfs", "ae", "os"], [0, 2, 0, 1]),
    "spec3": (["os", "pfs", "os", "ae"], [3, 0, 0, 0]),
    "spec4": (["ae", "resp"], [0, 0]),
}
summ, levels = [], []
for dname, rows_d in datasets.items():
    trt = [r for r in rows_d if r["arm"] == "T"]
    ctl = [r for r in rows_d if r["arm"] == "C"]
    for sname, (pri, thr) in specs.items():
        res, wk, lk = ref.gpc(trt, ctl, [EPS[p] for p in pri], thr)
        summ.append([dname, sname] + [fmt(res[k]) for k in
                                      ("p_win", "p_loss", "p_tie", "ntb", "ntb_se", "wr", "logwr_se", "wo")])
        for k in range(len(pri)):
            levels.append([dname, sname, k + 1, pri[k], thr[k], fmt(wk[k]), fmt(lk[k])])
write_csv("gpc_expected.csv", ["dataset", "spec", "p_win", "p_loss", "p_tie", "ntb", "ntb_se",
                               "wr", "logwr_se", "wo"], summ)
write_csv("gpc_expected_levels.csv", ["dataset", "spec", "level", "endpoint", "threshold", "win", "loss"],
          levels)
write_csv("gpc_specs.csv", ["spec", "level", "endpoint", "threshold"],
          [[s, k + 1, p[k], t[k]] for s, (p, t) in specs.items() for k in range(len(p))])

# Peron scores. The data set "cens" has heavy censoring, so that many pairs
# remain partly undecided, and the specifications use an endpoint again with a
# smaller threshold.
rng_c = np.random.RandomState(20261022)
cens_rows = []
for arm, n, scale in (("T", 30, 12.0), ("C", 25, 9.0)):
    for i in range(n):
        os_t = rng_c.exponential(scale)
        pfs_t = min(os_t, rng_c.exponential(scale / 2.0))
        cens = min(rng_c.uniform(1.0, 14.0), 10.0)
        cens_rows.append(dict(arm=arm,
                              os_time=round(min(os_t, cens), 6), os_event=int(os_t <= cens),
                              pfs_time=round(min(pfs_t, cens), 6), pfs_event=int(pfs_t <= cens),
                              resp=float(rng_c.uniform() < 0.4), ae=float(rng_c.uniform() < 0.3)))
datasets["cens"] = cens_rows
write_csv("gpc_cens.csv", ["arm", "os_time", "os_event", "pfs_time", "pfs_event", "resp", "ae"],
          [[r["arm"], r["os_time"], r["os_event"], r["pfs_time"], r["pfs_event"],
            r["resp"], int(r["ae"])] for r in cens_rows])
peron_specs = {
    "peron1": (["os", "pfs", "resp", "ae"], [0, 0, 0, 0]),
    "peron2": (["resp", "pfs", "ae", "os"], [0, 2, 0, 1]),
    "peron3": (["os", "pfs", "os", "ae"], [3, 0, 0, 0]),
    "peron4": (["os", "resp", "os", "pfs"], [2, 0, 0, 1]),
}
write_csv("gpc_peron_specs.csv", ["spec", "level", "endpoint", "threshold"],
          [[s_, k + 1, p_[k], t_[k]] for s_, (p_, t_) in peron_specs.items()
           for k in range(len(p_))])
summ, levels = [], []
for dname in ("ties", "cont", "cens"):
    rows_d = datasets[dname]
    trt = [r for r in rows_d if r["arm"] == "T"]
    ctl = [r for r in rows_d if r["arm"] == "C"]
    for sname, (pri, thr) in peron_specs.items():
        res, wk, lk = ref.gpc_peron(trt, ctl, [EPS[p] for p in pri], thr)
        summ.append([dname, sname] + [fmt(res[k]) for k in ("p_win", "p_loss", "p_tie", "ntb", "wr")])
        for k in range(len(pri)):
            levels.append([dname, sname, k + 1, pri[k], thr[k], fmt(wk[k]), fmt(lk[k])])
write_csv("gpc_peron_expected.csv", ["dataset", "spec", "p_win", "p_loss", "p_tie", "ntb", "wr"], summ)
write_csv("gpc_peron_expected_levels.csv",
          ["dataset", "spec", "level", "endpoint", "threshold", "win", "loss"], levels)

# ---------------------------------------------------------------------------
# 3. Benefit-risk scores
# ---------------------------------------------------------------------------
rng = np.random.RandomState(7)
br_rows = []
for g, n, med_pfs, med_os, orr, ae in (("Cohort1", 30, 8.0, 18.0, 0.45, 0.35),
                                       ("Cohort2", 25, 6.0, 15.0, 0.30, 0.20),
                                       ("Cohort3", 20, 5.0, 12.0, 0.25, 0.15)):
    for i in range(n):
        os_t = rng.exponential(med_os / math.log(2))
        pfs_t = min(os_t, rng.exponential(med_pfs / math.log(2)))
        cens = rng.uniform(6.0, 24.0)
        resp = float(rng.uniform() < orr)
        if g == "Cohort1" and i == 3:
            resp = float("nan")
        br_rows.append(dict(group=g, os_time=round(min(os_t, cens), 4), os_event=int(os_t <= cens),
                            pfs_time=round(min(pfs_t, cens), 4), pfs_event=int(pfs_t <= cens),
                            resp=resp, ae=float(rng.uniform() < ae)))
write_csv("br_data.csv", ["group", "os_time", "os_event", "pfs_time", "pfs_event", "resp", "ae"],
          [[r["group"], r["os_time"], r["os_event"], r["pfs_time"], r["pfs_event"], r["resp"], int(r["ae"])]
           for r in br_rows])

crit_target = [
    dict(endpoint="resp", measure="rate", time=None, target=0.30, weight=0.3, cutoff=0.5,
         prior_a=1.0, prior_b=1.0, label="resp"),
    dict(endpoint="pfs", measure="surv", time=6.0, target=0.50, weight=0.3, cutoff=0.0005,
         prior_a=0.5, prior_b=0.0, label="pfs_S6"),
    dict(endpoint="os", measure="surv", time=12.0, target=0.60, weight=0.2, cutoff=None,
         prior_a=0.5, prior_b=0.0, label="os_S12"),
    dict(endpoint="ae", measure="rate", time=None, target=0.30, weight=0.2, cutoff=0.6,
         prior_a=0.5, prior_b=0.5, label="ae"),
]
crit_ref = [
    dict(endpoint="resp", measure="rate", time=None, target=0.10, weight=0.25, cutoff=None,
         prior_a=0.5, prior_b=0.5, label="resp"),
    dict(endpoint="pfs", measure="surv", time=6.0, target=0.05, weight=0.25, cutoff=0.3,
         prior_a=0.5, prior_b=0.0, label="pfs_S6"),
    dict(endpoint="os", measure="hr", time=None, target=0.90, weight=0.25, cutoff=None,
         prior_a=1.0, prior_b=10.0, label="os_HR"),
    dict(endpoint="ae", measure="rate", time=None, target=0.10, weight=0.25, cutoff=0.5,
         prior_a=0.5, prior_b=0.5, label="ae"),
]
groups = {}
for r in br_rows:
    groups.setdefault(r["group"], []).append(r)
res_t = ref.benefit_risk(groups, EPS, crit_target)
res_r = ref.benefit_risk(groups, EPS, crit_ref, reference="Cohort2")
comp, summ = [], []
best = max((x for x in res_t if x["admissible"]), key=lambda x: x["BR"], default=None)
for mode, res, crit in (("target", res_t, crit_target), ("reference", res_r, crit_ref)):
    for x in res:
        for c, s in zip(crit, x["S"]):
            comp.append([mode, x["group"], c["label"], fmt(s)])
        sel = "NA" if mode == "reference" else ("TRUE" if best is not None and x["group"] == best["group"]
                                                else "FALSE")
        summ.append([mode, x["group"], fmt(x["BR"]), "TRUE" if x["admissible"] else "FALSE", sel])
write_csv("br_expected_scores.csv", ["mode", "group", "label", "S"], comp)
write_csv("br_expected_summary.csv", ["mode", "group", "BR", "admissible", "selected"], summ)

for name, crit in (("br_criteria_target.csv", crit_target), ("br_criteria_reference.csv", crit_ref)):
    write_csv(name, ["endpoint", "measure", "time", "target", "weight", "cutoff", "prior.a", "prior.b"],
              [[c["endpoint"], c["measure"], "NA" if c["time"] is None else c["time"], c["target"],
                c["weight"], "NA" if c["cutoff"] is None else c["cutoff"], c["prior_a"], c["prior_b"]]
               for c in crit])

print("fixtures written to", OUT)
