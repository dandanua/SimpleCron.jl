# edit ~/.julia/config/startup.jl
push!(LOAD_PATH, pwd())
using Revise
__revise_mode__ = :eval
# using Base.Threads: @spawn, Atomic
# Base.global_run = Atomic{Bool}(true)
# Base.exit_on_sigint(false)


using TestCron

@time TestCron.main()
