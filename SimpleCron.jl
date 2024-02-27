module SimpleCron
export Cron, start, stop, subscribe, unsubscribe, sleep_until

using Dates

mutable struct Cron
    const period::Period # no months or other non-constant
    phase::DateTime # in UTC. Local time shift fixed at the moment of creation. Doesn't change at summer/winter
    jobs::Set{Function}
    state::Symbol
    awake::Threads.Condition
    const lock::Threads.AbstractLock
    dynamic::Bool # can run functions defined in the future (are you sure you need that?)
end

function Cron(period::Period, phase::DateTime; dynamic::Bool=false)
    if typeof(period) in [Year, Quarter, Month]
        error("Non-constant period")
    elseif typeof(period) in [Microsecond, Nanosecond]
        error("Period is too small")
    elseif period.value < 0
        error("Negative period")
    end

    jobs = Set{Function}()
    lock = ReentrantLock()
    awake = Threads.Condition(lock)

    localshift = now(UTC) - now()
    return Cron(period, phase+localshift, jobs, :stop, awake, lock, dynamic)
end

# 2024-01-01 is Monday
Cron(period::Period, phase::Period = Day(0); dynamic=false) = Cron(period, DateTime("2024-01-01")+phase, dynamic=dynamic)

function sleep_until(future::DateTime)
    while true
        ms = (future - now(UTC)).value
        if ms < 0 break end
        if ms < 1000
            sleep(ms/1000)
            break
        else
            sleep(ms/2000)
        end
    end
end

function adjust_phase!(cron)
    d = now(UTC) - cron.phase
    (k,r) = divrem(d, cron.period)
    cron.phase += k*cron.period
    if r.value < 0 
        cron.phase += cron.period 
    end
    # assert phase <= now(UTC) < phase+period
    return cron.phase
end

function start(cron::Cron)
    @lock cron.lock begin 
        if (cron.state == :run) error("Already running") end
        cron.state = :run
    end

    # adjust_phase!(cron)
    while true
        adjust_phase!(cron) # a change of system UTC forwards won't cause "panic"
        cron.phase += cron.period
        cron.awake = Threads.Condition(cron.lock)
        @async begin
            sleep_until(cron.phase)
            @lock cron.lock notify(cron.awake)
        end
        @lock cron.lock begin
            wait(cron.awake)
            @show ("awake", cron.phase)

            if cron.state==:stop break end

            for job in cron.jobs
                if cron.dynamic==false
                    @async job()
                else
#                     eval(:(@async $job()))
                    @async invokelatest(job)
                end
            end
        end
    end
end

function subscribe(cron::Cron, job::Function) # job is 0-argument
    @lock cron.lock push!(cron.jobs, job)
end

function unsubscribe(cron::Cron, job::Function)
    @lock cron.lock delete!(cron.jobs, job)
end

function stop(cron::Cron)
    @lock cron.lock begin
        cron.state = :stop
        notify(cron.awake) # ensures that cron cycle breaks
    end
end

end
