Quick Presets

Apply common Wget configurations.

Custom Configuration Simple Resume Download Mirror Website (Offline Copy) Spider (Check Broken Links) Bulk Download (Input File)

Target

Target URL

Input File (-i)

Output Control

Save As (-O)

Directory Prefix (-P)

Continue (-c)Resume getting a partially-downloaded file.

No Clobber (-nc)Skip downloads that would overwrite existing files.

Timestamping (-N)Don't re-retrieve files unless newer than local.

Recursion & Mirroring

Mirror Mode (-m) Shortcut for -N -r -l inf --no-remove-listing. Best for backup

Recursive (-r)Specify recursive download.

Recursion Level (-l)

No Parent (-np)Don't ascend to the parent directory.

Convert Links (-k)Make links in downloaded HTML point to local files.

Page Requisites (-p)Get all images/css/js needed to display HTML page.

Filters

Accept List (-A)comma-separated

Reject List (-R)comma-separated

Authentication

Username (--user)

Password (--password)

Ask Password (--ask-password)Prompt for password instead of storing it.

Connection

User Agent (-U)

Timeout (-T)Seconds

Retries (-t)0=inf

No Check Cert (--no-check-certificate)Don't validate SSL server certificate.

Throttling & Delays

Limit Rate (--limit-rate)

Wait (-w)

Random Wait (--random-wait)Wait from 0.5 to 1.5 \* wait interval.

Debug & Misc

Spider (--spider)Don't download, just check if pages exist.

Restrict Filenames--restrict-file-names=windows

Ignore Length (--ignore-length)Ignore Content-Length header.

Logs

Log File (-o)

Append

Quiet (-q)Turn off output.

Verbose (-v)Detailed output (Default).

No Verbose (-nv)Turn off verbosity, but keep errors.

Batch Queue

Clear

Download .BAT

Queue is empty
