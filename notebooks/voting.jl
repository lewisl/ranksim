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
using BenchmarkTools

# %%
includet("../source/simrankvoting.jl")

# %%
# make an example

ballots_1 = [
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
countmap(ballots_1[:,1])

# %%
result = countmap(ballots_1[:,1])

# %%
findmin(result)

# %%
find_losers(ballots_1, 1, [result])

# %%
vote_count(ballots_1, quiet=false)

# %%
vote_count(ballots_1)

# %%
vote_count(ballots_2, quiet=false)

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
ballots_3 = setup_ballots(prs,n_voters=10_000_000, n_cans=n_cans, n_ranks=n_ranks)

# %%
vote_count(ballots_3)

# %%
ballots_4 = [
    1  2  3  5;
    1  2  3  4;
    1  2  4  3;
    2  1  4  5;
    2  1  3  4;
    3  1  5  4;
    3  4  5  1;
    4  3  2  5;
    4  2  1  5;
    5  1  2  4;
    5  3  2  4
]


# %%
vote_count(ballots_4, quiet=false)

# %%
countmap(ballots_4[4:11,1:2], alg=:dict)

# %%
countmap(ballots_4[4:11,1:2], alg=:dict)

# %% tags=[]
ballots_5 = [
    1  2  3  5;
    1  2  3  4;
    1  2  4  3;
    2  3  4  5;
    2  3  5  4;
    3  2  5  4;
    3  4  5  1;
    4  3  2  5;
    4  3  1  5;
    5  3  2  4;
    5  3  2  4
]


# %% tags=[]
vote_count(ballots_5, quiet = false)

# %%
countmap(ballots_5[:,1:3],alg=:dict)

# %%
ballots_6 = [
  1   3   2;
  2   1   3;
  3   2   1;
  1   3   2;
  2   1   3
]

# %%
vote_count(ballots_6, quiet=false)

# %% tags=[]
ballots_7 = [
  1  2  3;
  1  2  3;
  1  3  2;
  2  3  1;
  2  3  1;
  2  3  1;
  3  2  1;
  3  2  1;
]

# %%
vote_count(ballots_7)

# %% [markdown]
# ## use code to create runoff for tied "losers"

# %%
bsub = ballots_5[4:11,1:2]
res = countmap(bsub[:,1])
useranks = fill(1,8)

# %%
w = vote_count(bsub, quiet=true, stopstep=2)

# %%
w[1]

# %%
d = Dict(5=>0,4=>1,2=>1,3=>6)

# %%
maxv = -typemin(Int)
maxk = 0
for pr in d
    if pr[2] > maxv
        maxv = pr[2]; maxk = pr[1]
    end
end
(mk, mv)
>(6,3)

# %%
function dictcomp(dd, op)
    selv = if op == < 
        typemax(valtype(dd)) 
    elseif op == >
        typemin(valtype(dd))
    else
        @assert false "Op must be > or <"
    end
    selk = 0
    for pr in dd
        if op(pr[2],selv)
            selv = pr[2]; selk = pr[1]
        end
    end
    return selk=>selv
end
            

# %%
eltype(d)

# %%
eltype(ans)

# %%
findall(indexin(ballots_5[:,1], [2,3,4,5]) .!= nothing)

# %%
losers = [4,5,3,2]
pos = findall(indexin(losers, [3]) .!= nothing)
deleteat!(losers, pos)

# %%
result5 = countmap(ballots_5[:,1], alg=:dict)

# %%
find_losers(ballots_5, 1, [result5])

# %%
ballots_5

# %%
vote_count(ballots_5,quiet=false)

# %%
