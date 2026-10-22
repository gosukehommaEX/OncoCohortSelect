"""Fictitious completed trial with three single-arm cohorts (inst/extdata/example_trial.csv).

Run from the root of the package:

    python data-raw/make_example_trial.py

The data are invented for the vignette "Analyzing a completed trial". They
have one row per patient and column names in the style of ADaM data sets:

    USUBJID  patient identifier
    TRT01P   cohort
    OSAVAL   overall survival time (months)
    OSCNSR   censoring indicator of overall survival (0 = death, 1 = censored)
    PFSAVAL  progression-free survival time (months)
    PFSCNSR  censoring indicator of progression-free survival (0 = event)
    BOR      best overall response (CR, PR, SD, PD or NE)
    AEFL     adverse event of interest ("Y" or blank)

Patients are enrolled uniformly over 12 months and analyzed at month 24.
Responders have a lower hazard of progression, 15% of PFS events are deaths,
overall survival after progression is exponential, and the adverse event is
independent of the other endpoints.
"""

import csv
import math
import os

import numpy as np

COHORTS = [
    # label, n, ORR, PFS median of non-responders, AE rate
    ("Cohort 1", 40, 0.30, 4.5, 0.20),
    ("Cohort 2", 40, 0.45, 5.0, 0.30),
    ("Cohort 3", 40, 0.50, 5.5, 0.45),
]
HR_RESPONDER = 0.5      # hazard ratio of progression or death, responders vs non-responders
DEATH_PROP = 0.15       # proportion of PFS events that are deaths
PPS_MEDIAN = 9.0        # median survival after progression (months)
ACCRUAL = 12.0          # accrual period (months)
CUTOFF = 24.0           # calendar time of the analysis (months)
DROPOUT = -math.log(0.95) / 12  # 5% per year

rng = np.random.RandomState(20261022)
rows = []
for label, n, orr, pfs_med, ae_rate in COHORTS:
    lam = math.log(2) / pfs_med
    for i in range(n):
        resp = rng.uniform() < orr
        pfs = rng.exponential(1 / (lam * (HR_RESPONDER if resp else 1.0)))
        death = rng.uniform() < DEATH_PROP
        os_t = pfs if death else pfs + rng.exponential(PPS_MEDIAN / math.log(2))
        entry = rng.uniform(0, ACCRUAL)
        cens = min(CUTOFF - entry, rng.exponential(1 / DROPOUT))
        if resp:
            bor = "CR" if rng.uniform() < 0.2 else "PR"
        elif rng.uniform() < 0.05:
            bor = "NE"
        else:
            bor = "PD" if min(pfs, cens) < 2 else "SD"
        ae = rng.uniform() < ae_rate
        rows.append([
            "%s-%03d" % (label.replace("Cohort ", "C"), i + 1), label,
            "%.2f" % min(os_t, cens), int(os_t > cens),
            "%.2f" % min(pfs, cens), int(pfs > cens),
            bor, "Y" if ae else "",
        ])

out = os.path.join("inst", "extdata", "example_trial.csv")
with open(out, "w", newline="") as f:
    w = csv.writer(f, lineterminator="\n")
    w.writerow(["USUBJID", "TRT01P", "OSAVAL", "OSCNSR", "PFSAVAL", "PFSCNSR", "BOR", "AEFL"])
    w.writerows(rows)
print("written", out, len(rows), "patients")
