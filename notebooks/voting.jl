# ---
# jupyter:
#   jupytext:
#     formats: ipynb,jl:percent
#     text_representation:
#       extension: .jl
#       format_name: percent
#       format_version: '1.3'
#       jupytext_version: 1.11.2
#   kernelspec:
#     display_name: Julia 1.6.0
#     language: julia
#     name: julia-1.6
# ---

# %%
using StatsBase
using Distributions
using Plots
using Random

# %%
includet("../source/simrankvoting.jl")

# %%
# make an example

ballots = [
    1  2  3  5;
    2  1  3  4;
    1  2  4  3;
    1  2  5  3;
    2  1  4  5;
    2  1  3  4;
    2  1  3  4;
    1  3  4  2;
    3  1  5  4;
    3  4  5  1;
    4  3  2  1;
    4  5  3  2
]

# %%
countmap(ballots[:,1])

# %%
result = countmap(ballots[:,1])

# %%
findmin(result)

# %%
find_losers(ballots, 1, [result])

# %%
vote_count(ballots, quiet=false)

# %%
vote_count(ballots)

# %%
vote_count(ballots_2)

# %%
ballots_2 = [
    1  2  3  5;
    1  2  3  4;
    1  2  4  3;
    1  2  5  3;
    2  1  4  5;
    2  1  3  4;
    2  1  3  4;
    2  3  4  1;
    3  1  5  4;
    3  4  5  1;
    3  1  2  4;
    3  5  4  2
]

# %%
breakdown(ballots_2, 1)

# %%
breakdown(ballots_2, 1.0)

# %% [markdown]
# # Create rank distribution vectors

# %%
n_cans = 6 # number of candidates
n_ranks = 4 # how many rankings for each candidate
n_voters = 100

# %%
r = 2  #  rth success
p = 0.35  #  probability of success in a given trial
# outcome is number of failures before the rth success
nb = NegativeBinomial(r,p)
pd = [pdf(nb,i) for i in 1:n_cans]
sum(pd)

# %%
plot(pd)

# %%
pd

# %%
pd[:] = pd[1:end] ./ sum(pd[1:end])

# %%
sum(pd)

# %%
reverse(pd)

# %%
pd = nbtrials()

# %%
hcat([circshift(pd,i) for i in 0:n_ranks-1]...)

# %%
prs = nbtrials(r=2, p=0.35, n_cans=6, n_ranks=4)

# %%
countmap(categorical_sim(prs[:,1], n_voters))

# %%
setup_ballots(prs,n_voters=100, n_cans=n_cans, n_ranks=n_ranks)

# %%
@time iseven(4)

# %%
f(n,m) = n == m ? m : mod(n,m)

# %%
f(1,5)

# %%
