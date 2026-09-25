ss -tlnp
#ss = show socket statistics
# -t = show only TCP sockets
# -l = show only listening sockets
# -n = show numebrical IP address ports (i.e. 0.0.0.0:22 instead of ssh)
# -p = show the process associated with that port

ps -ef | grep "python"
#ps = show process status
#-e = show processes for all users, not just current users' processes
#-f = show full format, including:

#UID (Which user owns the process)
#PID (Process ID)
#PPID (Parent Process ID)
#Process start time
#Terminal that is controlling the process
#CPU time (amount of time that a process used the CPU to run, when used with 
#Cron, shows per process run
#CPU time includes utime (User time = time the CPU spent running the programs 
#own code, stime = System time the time the program spent running kernel operations on behalf of the program
