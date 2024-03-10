# edit ~/.julia/config/startup.jl
# push!(LOAD_PATH, pwd())
# using Revise
# __revise_mode__ = :eval

include("SimpleCrons.jl")
using .SimpleCrons, Dates, Base.Threads

function main()
    c = Cron(Millisecond(5), dynamic = true)
#     @show c
    @spawn start(c)

    yo() = (println(now()))
    @spawn subscribe(c, yo)
#     stop(c)
    # @spawn start(c)
#     @show c
    sleep(1/20)
#     SimpleCron.sleep_until(now(UTC)+Millisecond(100))
    @show c.phase
    stop(c)
end

@time main()