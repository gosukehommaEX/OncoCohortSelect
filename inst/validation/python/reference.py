"""Independent reference implementations for OncoCohortSelect.

The functions below are written separately from the R code of the package and
are used to compute the expected values of the tests (see make_fixtures.py).

* Posterior probabilities: one-sample probabilities from scipy.stats, and
  two-sample probabilities by adaptive quadrature (scipy.integrate.quad) over
  the density of the treatment parameter, instead of the Gauss-Legendre rule on
  the probability scale used in R.
* Generalized pairwise comparisons: an explicit loop over pairs. Whether one
  true event time exceeds another is decided by interval reasoning on the
  possible true times (a censored time t means that the true time is larger
  than t), instead of the matrix formulation used in R.
"""

import math

import numpy as np
from scipy import integrate, stats

QUAD = dict(limit=1000, epsabs=1e-13, epsrel=1e-12)


# ---------------------------------------------------------------------------
# Posterior probabilities
# ---------------------------------------------------------------------------

def prob_rate_one(a, b, target, higher):
    """P(p >= target) or P(p <= target) for p ~ Beta(a, b)."""
    p_hi = stats.beta.sf(target, a, b)
    return p_hi if higher else 1.0 - p_hi


def prob_surv_one(a, b, time, target, higher):
    """P(S(time) >= target) or <= for S(t) = exp(-lam t), lam ~ Gamma(a, rate b)."""
    lam_max = -math.log(target) / time
    p_hi = stats.gamma.cdf(lam_max, a, scale=1.0 / b)
    return p_hi if higher else 1.0 - p_hi


def prob_rate_two(a, b, ar, br, margin, higher):
    """P(p - p_ref >= margin) (higher) or P(p - p_ref <= margin)."""
    t = stats.beta(a, b)
    r = stats.beta(ar, br)
    lo = max(0.0, margin)
    hi = min(1.0, 1.0 + margin)
    if hi > lo:
        v, _ = integrate.quad(lambda x: t.pdf(x) * r.cdf(x - margin), lo, hi, **QUAD)
    else:
        v = 0.0
    # region where x - margin >= 1, i.e. the whole reference distribution lies below
    v += t.sf(hi) if hi < 1.0 else 0.0
    return v if higher else 1.0 - v


def prob_surv_two(a, b, ar, br, time, margin, higher):
    """P(S(time) - S_ref(time) >= margin) (higher) or <= margin."""
    t = stats.gamma(a, scale=1.0 / b)
    r = stats.gamma(ar, scale=1.0 / br)

    def integrand(lam):
        s = math.exp(-time * lam) - margin
        if s <= 0.0:
            return 0.0
        if s >= 1.0:
            return t.pdf(lam)
        # P(S_ref <= s) = P(lam_ref >= -log(s) / time)
        return t.pdf(lam) * r.sf(-math.log(s) / time)

    # split the range at the quantiles of the treatment parameter for accuracy
    qs = [t.ppf(p) for p in (1e-12, 0.001, 0.1, 0.5, 0.9, 0.999, 1 - 1e-12)]
    edges = [0.0] + qs + [np.inf]
    v = 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        part, _ = integrate.quad(integrand, lo, hi, **QUAD)
        v += part
    return v if higher else 1.0 - v


def prob_hr(a, b, ar, br, bound, higher):
    """P(lam / lam_ref <= bound) (higher, longer times better) or >= bound."""
    t = stats.gamma(a, scale=1.0 / b)
    r = stats.gamma(ar, scale=1.0 / br)
    qs = [t.ppf(p) for p in (1e-12, 0.001, 0.1, 0.5, 0.9, 0.999, 1 - 1e-12)]
    edges = [0.0] + qs + [np.inf]
    v = 0.0
    for lo, hi in zip(edges[:-1], edges[1:]):
        part, _ = integrate.quad(lambda x: t.pdf(x) * r.sf(x / bound), lo, hi, **QUAD)
        v += part
    return v if higher else 1.0 - v


def posterior_prob(measure, a, b, target, time=None, ar=None, br=None, higher=True):
    if ar is None:
        if measure == "rate":
            return prob_rate_one(a, b, target, higher)
        if measure == "surv":
            return prob_surv_one(a, b, time, target, higher)
        raise ValueError("hr needs a reference")
    if measure == "rate":
        return prob_rate_two(a, b, ar, br, target, higher)
    if measure == "surv":
        return prob_surv_two(a, b, ar, br, time, target, higher)
    return prob_hr(a, b, ar, br, target, higher)


# ---------------------------------------------------------------------------
# Benefit-risk score
# ---------------------------------------------------------------------------

def sufficient(rows, ep):
    """(successes, patients) for binary, (events, total time) for tte."""
    if ep["type"] == "binary":
        vals = [r[ep["var"]] for r in rows if not _isnan(r[ep["var"]])]
        return float(sum(vals)), float(len(vals))
    return float(sum(r[ep["event"]] for r in rows)), float(sum(r[ep["time"]] for r in rows))


def benefit_risk(groups, eps, crit, reference=None):
    """groups: dict label -> list of row dicts; crit: list of component dicts.

    Returns a list of dicts with group, S (list), admissible, BR.
    """
    post = {}
    for g, rows in groups.items():
        post[g] = []
        for c in crit:
            ep = eps[c["endpoint"]]
            s1, s2 = sufficient(rows, ep)
            if ep["type"] == "binary":
                post[g].append((c["prior_a"] + s1, c["prior_b"] + s2 - s1))
            else:
                post[g].append((c["prior_a"] + s1, c["prior_b"] + s2))
    out = []
    labels = [g for g in groups if g != reference]
    for g in labels:
        S = []
        for k, c in enumerate(crit):
            ep = eps[c["endpoint"]]
            a, b = post[g][k]
            if reference is None:
                S.append(posterior_prob(c["measure"], a, b, c["target"], c.get("time"),
                                        higher=ep["higher"]))
            else:
                ar, br = post[reference][k]
                S.append(posterior_prob(c["measure"], a, b, c["target"], c.get("time"),
                                        ar, br, higher=ep["higher"]))
        logbr = sum(c["weight"] * math.log(s) for c, s in zip(crit, S) if c["weight"] > 0)
        adm = all(s >= c["cutoff"] for c, s in zip(crit, S) if c["cutoff"] is not None)
        out.append(dict(group=g, S=S, admissible=adm, BR=math.exp(logbr)))
    return out


# ---------------------------------------------------------------------------
# Generalized pairwise comparisons (Gehan scoring)
# ---------------------------------------------------------------------------

def _isnan(x):
    return x is None or (isinstance(x, float) and math.isnan(x))


def known_longer(t_a, e_a, t_b, e_b, thr):
    """True if the true time of a is known to exceed that of b.

    By at least thr when thr > 0, and strictly when thr == 0. A censored time t
    means that the true time is larger than t; an event time is exact.
    """
    if e_b == 0:
        return False  # the true time of b is not bounded above
    diff = t_a - t_b  # lower bound of (true a - true b), strict if a is censored
    if thr > 0:
        return diff >= thr
    return diff > 0 or (diff == 0 and e_a == 0)


def score_pair(ep, x, y, thr):
    """+1 if the treatment patient x wins, -1 if it loses, 0 otherwise."""
    if ep["type"] == "binary":
        u, v = x[ep["var"]], y[ep["var"]]
        if _isnan(u) or _isnan(v) or u == v:
            return 0
        better = u > v if ep["higher"] else u < v
        return 1 if better else -1
    tx, ex = x[ep["time"]], x[ep["event"]]
    ty, ey = y[ep["time"]], y[ep["event"]]
    x_longer = known_longer(tx, ex, ty, ey, thr)
    y_longer = known_longer(ty, ey, tx, ex, thr)
    if ep["higher"]:
        return 1 if x_longer else (-1 if y_longer else 0)
    return 1 if y_longer else (-1 if x_longer else 0)


def gpc(trt, ctl, eps_ordered, thresholds):
    """Generalized pairwise comparison of the treatment rows with the control rows."""
    m, n = len(trt), len(ctl)
    K = len(eps_ordered)
    W = np.zeros((m, n))
    L = np.zeros((m, n))
    win_k = np.zeros(K)
    loss_k = np.zeros(K)
    for i in range(m):
        for j in range(n):
            for k in range(K):
                s = score_pair(eps_ordered[k], trt[i], ctl[j], thresholds[k])
                if s == 1:
                    W[i, j] = 1
                    win_k[k] += 1
                    break
                if s == -1:
                    L[i, j] = 1
                    loss_k[k] += 1
                    break
    pw, pl = W.mean(), L.mean()
    # first-order H-decomposition of the two U-statistics
    hw_t = np.array([W[i, :].mean() - pw for i in range(m)])
    hw_c = np.array([W[:, j].mean() - pw for j in range(n)])
    hl_t = np.array([L[i, :].mean() - pl for i in range(m)])
    hl_c = np.array([L[:, j].mean() - pl for j in range(n)])
    vw = (hw_t ** 2).sum() / m ** 2 + (hw_c ** 2).sum() / n ** 2
    vl = (hl_t ** 2).sum() / m ** 2 + (hl_c ** 2).sum() / n ** 2
    cv = (hw_t * hl_t).sum() / m ** 2 + (hw_c * hl_c).sum() / n ** 2
    ntb = pw - pl
    res = dict(p_win=pw, p_loss=pl, p_tie=1 - pw - pl, ntb=ntb,
               ntb_se=math.sqrt(max(vw + vl - 2 * cv, 0.0)),
               wr=pw / pl if pl > 0 else float("inf"),
               logwr_se=math.sqrt(max(vw / pw ** 2 + vl / pl ** 2 - 2 * cv / (pw * pl), 0.0))
               if pw > 0 and pl > 0 else float("nan"),
               wo=(1 + ntb) / (1 - ntb))
    return res, win_k / (m * n), loss_k / (m * n)


# ---------------------------------------------------------------------------
# Generalized pairwise comparisons with the scoring rule of Peron
# ---------------------------------------------------------------------------
# Each censored observation is replaced by its conditional distribution given
# survival beyond the censoring time, estimated by the Kaplan-Meier estimator of
# its group: point masses at the later event times and a tail mass beyond the
# last observed time, whose location is unknown. An event time is a point mass
# 1. The probability that a pair is favorable is the total mass of the
# combinations for which the treatment time is certainly longer by at least
# the threshold (strictly longer with a threshold of 0); the tail mass counts
# only when the comparison is certain whatever its location. The unfavorable
# probability is defined symmetrically.
#
# The weight of a pair at a priority level is the product, over the other
# endpoints already analyzed, of the probability that the pair is undecided at
# the last threshold of that endpoint. When an endpoint is analyzed again with a
# smaller threshold, the probabilities at the previous threshold are subtracted,
# since a pair favorable at the larger threshold is favorable at the smaller
# one. This is the rule of the BuyseTest package; with scores of 0 and 1 it
# reduces to passing the undecided pairs to the next level.

def kaplan_meier(times, events):
    """Event times, survival just after each event time, last observed time."""
    ut = sorted(set(t for t, e in zip(times, events) if e == 1))
    surv, s = [], 1.0
    for u in ut:
        d = sum(1 for t, e in zip(times, events) if e == 1 and t == u)
        r = sum(1 for t in times if t >= u)
        s *= 1.0 - d / r
        surv.append(s)
    return ut, surv, max(times)


def km_survival(km, t):
    ut, surv, tmax = km
    s = 1.0
    for u, v in zip(ut, surv):
        if u <= t:
            s = v
    return s


def conditional_masses(km, t, event):
    """Point masses (location, mass) and tail mass of the true time."""
    if event == 1:
        return [(t, 1.0)], 0.0
    ut, surv, tmax = km
    st = km_survival(km, t)
    pts, prev = [], st
    for u, v in zip(ut, surv):
        if u > t:
            pts.append((u, (prev - v) / st))
            prev = v
    return pts, km_survival(km, tmax) / st


def peron_pair(km_t, km_c, x, ex, y, ey, thr):
    """Lower bounds of P(treatment longer) and P(control longer)."""
    pt, tail_t = conditional_masses(km_t, x, ex)
    pc, tail_c = conditional_masses(km_c, y, ey)
    tmax_t, tmax_c = km_t[2], km_c[2]

    def longer(a, b):  # a certainly longer than b
        return (a - b >= thr) if thr > 0 else (a - b > 0)

    def longer_tail(tmax, b):  # a true time beyond tmax is certainly longer than b
        return (tmax - b >= thr) if thr > 0 else (tmax - b >= 0)

    fav = sum(ma * mb for a, ma in pt for b, mb in pc if longer(a, b))
    fav += tail_t * sum(mb for b, mb in pc if longer_tail(tmax_t, b))
    unf = sum(ma * mb for a, ma in pt for b, mb in pc if longer(b, a))
    unf += tail_c * sum(ma for a, ma in pt if longer_tail(tmax_c, a))
    return fav, unf


def gpc_peron(trt, ctl, eps_ordered, thresholds):
    """Generalized pairwise comparison with Peron scores for time-to-event endpoints."""
    m, n = len(trt), len(ctl)
    K = len(eps_ordered)
    W = np.zeros((m, n))
    L = np.zeros((m, n))
    win_k = np.zeros(K)
    loss_k = np.zeros(K)
    rest, fav_prev, unf_prev = {}, {}, {}
    for k, ep in enumerate(eps_ordered):
        name = ep["name"]
        if ep["type"] == "tte":
            km_t = kaplan_meier([r[ep["time"]] for r in trt], [r[ep["event"]] for r in trt])
            km_c = kaplan_meier([r[ep["time"]] for r in ctl], [r[ep["event"]] for r in ctl])
        F = np.zeros((m, n))
        U = np.zeros((m, n))
        for i in range(m):
            for j in range(n):
                if ep["type"] == "binary":
                    s = score_pair(ep, trt[i], ctl[j], thresholds[k])
                    f, u = float(s == 1), float(s == -1)
                else:
                    tl, cl = peron_pair(km_t, km_c, trt[i][ep["time"]], trt[i][ep["event"]],
                                        ctl[j][ep["time"]], ctl[j][ep["event"]], thresholds[k])
                    f, u = (tl, cl) if ep["higher"] else (cl, tl)
                F[i, j], U[i, j] = f, u
        w = np.ones((m, n))
        for other, r in rest.items():
            if other != name:
                w = w * r
        dF = F - fav_prev.get(name, 0.0)
        dU = U - unf_prev.get(name, 0.0)
        W += w * dF
        L += w * dU
        win_k[k] = (w * dF).sum()
        loss_k[k] = (w * dU).sum()
        rest[name] = np.maximum(1.0 - F - U, 0.0)
        fav_prev[name], unf_prev[name] = F, U
    pw, pl = W.mean(), L.mean()
    return dict(p_win=pw, p_loss=pl, p_tie=1 - pw - pl, ntb=pw - pl,
                wr=pw / pl if pl > 0 else float("inf")), win_k / (m * n), loss_k / (m * n)
