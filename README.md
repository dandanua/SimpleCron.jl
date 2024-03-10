# SimpleCrons.jl

Simple cron jobs in Julia. Only a single constant period is supported in one instance of Cron. So no months or other non-constant periods.

<!-- ## Installation 

Install SimpleCrons.jl using the Julia package manager:

```julia
import Pkg
Pkg.add("SimpleCrons")
``` -->

## Usage 

To define a cron you simply supply a period and a phase
```julia
using Dates
using SimpleCrons

cron = Cron(Week(1), DateTime("2024-01-02T08:30"))
```
This will be triggered every Tuesday at 08:30 (since `2024-01-01` is Monday). Alternatively, you can supply a phase shift to `2024-01-01T00:00:00` instead of specifying a full date, i.e.
```julia 
cron = Cron(Day(1), Hour(21)+Minutes(15))
```
will be triggered each day at `21:15`. 

To add jobs you subscribe to a cron

```julia
subscribe(cron, func)
```
where `func` is a 0-argument function that will be run as a task. You can unsubscribe if needed. 

Then you start a cron 
```julia
start(cron)
```
and stop it if necessary.

You can subscribe functions to a cron which where defined after the cron was started, but only if the cron was created with the dynamic keyword
```julia 
cron = Cron(Week(1), Day(3)+Hour(8), dynamic = true)
start(cron)
hello() = println("Hello Thursday world!")
subscribe(cron, hello)
```

## Notes 

- Thread safe
- Phase in definition should be in local time, but internally cron uses UTC time. This means summer/winter time shift won't cause any problems, though the phase will be shifted. 
- System UTC forward time change won't cause any problems. A backward time change will cause cron to wait longer for the future. 
- You can't fetch or wait for tasks that a cron runs. You can use other Julia constructs for that or modify the Cron code if necessary. 