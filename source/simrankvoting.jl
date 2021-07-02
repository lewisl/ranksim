using Distributions
using Plots
using StatsBase
using PrettyPrint



"""
    setup_ballots(canprs; n_voters=100, n_cans=6, n_ranks=4)

Create sample ballots for the vote ranking simulation.
"""
function setup_ballots(canprs; n_voters=100, n_cans=6, n_ranks=4)
    ballots = zeros(Int, n_voters, n_ranks)

    ballots[:,1] .= categorical_sim(canprs[:,1], n_voters)
    for i = 2:n_ranks
        ballots[:,i] = circ.(ballots[:,i-1] .+ 1, n_cans)
    end
    return ballots
end


function vote_count(ballots; quiet=true)
    n_voters, n_ranks = size(ballots)
    n_cans = length(Set(ballots)) 
    result = Dict{Int, Int}[]

    # conduct first round
    step = 1  
    push!(result, countmap(ballots[:, step]))  # this ignores candidates with zero votes--they are automatically OUT

    winbool, maxpct, maxcan = iswinner(result[step])  # is there a round 1 winner?
    if winbool
        return result, maxpct, maxcan
    else  # no majority winner: apply instant-runoff ranked voting   
        useranks = fill(step, n_voters) # next rank to be used per voter  TODO IS THIS THE RIGHT STEP?
        instant_runoff!(result, ballots,  step, useranks, quiet)
    end

end


function instant_runoff!(result, ballots,  step, useranks, quiet)
    n_voters, n_ranks = size(ballots)

    for step = 2:99
        # start with results at end of previous round
        push!(result, result[step-1]) 

        if length(keys(result[step]))  == 2
            # we must either have a winner or a tie
            quiet || println("got to exactly 2 candidates in step $step")
            if tie(result[step]) # we have a tie
                quiet || begin
                            println("starting position"); println("Tie!"); pprintln(result[step])
                         end
                losers = []; voteridx = 1:size(ballots,1) # no losers--keep call candidates; use all voters choices
                reassigned = allocate_votes!(result, ballots, losers, step, voteridx, useranks)
                quiet || begin
                            println("outcome");     pprintln(result[step])
                            println("reassigned");  pprintln(reassigned)
                        end
                break
            else
                quiet || pprintln(result[step])
                break
            end
            
        elseif length(keys(result[step])) == 1
            # this must be the winner--or the algorithm didn't work
            quiet || begin
                        println("got to exactly 1 candidate in step $step")
                        pprintln(result[step])
                     end
            break
        else   
            # we have 3 or more remaining candates
            quiet || println("got to more than 3 candidates in step $step")
            if tie(result[step]) # we have a tie
                quiet || begin
                            println("starting position"); println("Tie!"); pprintln(result[step])
                        end
                losers = []; voteridx = 1:size(ballots,1) # no losers--keep call candidates; use all voters choices
                reassigned = allocate_votes!(result, ballots, losers, step, voteridx, useranks)  
                quiet || begin
                            println("outcome");     pprintln(result[step])
                            println("reassigned");  pprintln(reassigned)
                        end
            else
                quiet || begin
                            println("starting position");   pprintln(result[step])
                        end
                minvote, losers, voteridx = find_losers(ballots, step-1, result, mode=:all)
                quiet || println("Eliminating candidates: $losers")
                reassigned = allocate_votes!(result, ballots, losers, step, voteridx, useranks)
                quiet || begin
                            println("outcome");     pprintln(result[step])
                            println("reassigned");  pprintln(reassigned)
                         end
            end
        end
    end
    println("Final outcome")
    pprintln(result[step])
end


function allocate_votes!(result, ballots, losers, step, voteridx, useranks)
    n_voters, n_ranks = size(ballots)

    currentresult = result[step]
    reassigned = Dict{Pair, Int}()

    for i in losers
        delete!(currentresult, i)
    end
    # assign votes to remaining candidates and advance these voters userank
    for i in voteridx  # loop through voters who chose losers
        while true
            useranks[i] = useranks[i] + 1 > n_ranks ? -99 : useranks[i] + 1 # get next ranking for this voter
            if useranks[i] > 0
                newvote = ballots[i, useranks[i]]
                oldvote = ballots[i, useranks[i]-1]
                if haskey(currentresult, newvote)
                    currentresult[newvote] += 1 # assign votes to next choice
                    # reassigned[newvote] += 1
                    setindex!(reassigned, get(reassigned, oldvote=>newvote, 0) + 1, oldvote=>newvote)
                    break
                end
            else
                break
            end
        end
    end
    return reassigned
end


function find_losers(ballots, step, result; mode=:all)
    if mode == :all
        mv, losers = findallmins(result[step])
        losers = collect(losers)
    elseif mode == :first
        mv, losers = findmin(result[step])
        losers = [losers]
    else
        @assert false "Mode must be :all or :first"
    end

    # index of voters who chose losing candidate(s)
    loseridx = findall(indexin(ballots[:, step], losers) .!= nothing)

    return mv, losers, loseridx
end


function findallmins(result)
    minv = minimum(values(result))
    mindict = Dict(i => result[i] for i in keys(result) if result[i] == minv)
    return minv, keys(mindict)
end


function iswinner(result)
    pctofvotes = Dict(i => result[i] / sum(values(result)) for i in keys(result))
    maxpct, maxcan = findmax(pctofvotes)
    return maxpct > 0.5, maxpct, maxcan
end


tie(d) = all(y->y[2] == first(d)[2], d)
# tie(d,n) = all(map(y->y[2] == first(j)[2], j=sort(collect(d), by=y->y[2], rev=true)[1:n]))

function tie(d::Dict,n::Int)
    j=sort(collect(d), by=y->y[2], rev=true)
    tie(j[1:n])
end


function breakdown(ballot, type::Int)
    n_cans = length(Set(ballot))
    n_steps = size(ballot, 2)
    bd = zeros(Int, n_cans, n_steps)
    for step in 1:n_steps
        res = countmap(ballot[:, step])
        for i in keys(res)
            bd[i,step] = res[i]
        end
    end
    bd
end

function breakdown(ballot, type::Float64)
    bd1 = breakdown(ballot, 1)
    bd2 = zeros(size(bd1))
    for j in 1:size(bd2, 2)
        for i in 1:size(bd2, 1)
            bd2[i,j] = bd1[i,j] / sum(bd1[:,j])
        end
    end
    bd2
end



"""
    nbtrials(;r=2, p=0.35, n_cans=6, n_ranks=4)

Use the negative binomial distribution to create probabilities
for each candidate's ranking outcomes. The probabilities are 
used to create a random sampling of ranked voting ballots for
all the voters in the simulation.
"""
function nbtrials(;r=2, p=0.35, n_cans=6, n_ranks=4)
    r = 2  #  rth success
    p = 0.35  #  probability of success in a given trial
    # outcome is number of failures before the rth success
    nb = NegativeBinomial(r,p)

    # probability density for first n_cans outcomes, normalized to sum to 1.0
    pd = [pdf(nb,i) for i in 1:n_cans]
    pd[:] = pd[1:end] ./ sum(pd[1:end])
    hcat([circshift(pd,i) for i in 0:n_ranks-1]...)
end


function setup_candidates(n_cans=8, names=String[])
    maxcan = 15
    @assert n_cans isa Int "Number of candidates must be an integer from 3 to $maxcan."
    @assert 2 < n_cans < maxcan + 1 "Number of candidates must be an integer from 3 to $maxcan."

    letters = string.(collect('a':'o'))
    l = length(names) < 16 ? length(names) : maxcan
    names = vcat(names[1:l], letters[l+1:n_cans])
    d = Dict(i => names[i] for i in 1:n_cans)

end

"""
    categorical_sim(prs::Vector{Float64}, do_assert=true)
    categorical_sim(prs::Vector{Float64}, n::Int, do_assert=true)

Approximates sampling from a categorical distribution.
prs is an array of floats that must sum to 1.0.
do_assert determines if an assert tests this sum. For a single trial, this runs
in 10% of the time of rand(Categorical(prs)). For multiple trials, the 
second method runs in less than 50% of the time.

The second method generates results for n trials. 
The assert test is done only once if do_assert is true.
"""
function categorical_sim(prs, do_assert=true)
    do_assert && @assert isapprox(sum(prs), 1.0)
    x = rand()
    cumpr = 0.0
    i = 0
    for pr in prs
        cumpr += pr
        i += 1
        if x <= cumpr 
            break
        end
    end
    i
end

function categorical_sim(prs, n::Int, do_assert=true)
    do_assert && @assert isapprox(sum(prs), 1.0)
    ret = Vector{Int}(undef, n)
    
    @inbounds for i in 1:n
        ret[i] = categorical_sim(prs, false)
    end
    ret
end


#########################################################
# test ballots
#########################################################

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