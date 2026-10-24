Quick Presets

Apply common Robocopy configurations instantly.

Custom Configuration Mirror (Clone Directory) Backup (New/Changed) Move (Delete Source) Sync (Mirror + Security)

Source and Destination

Source Directory

Destination Directory

File Selection Default: \*.\*

Operation Mode

Standard Copy Copies new/changed files. Keeps extras.

Mirror (/MIR) Mirrors a directory tree (equivalent to /E plus /PURGE). Deletes Extras

Move Files (/MOV) Moves files (deletes from source after copying).

Move Tree (/MOVE) Moves files and directories (deletes from source after copying).

Directory & File behavior

Recursive (/E) Copies subdirectories, including empty ones.

Subdirectories (/S) Copies subdirectories, excluding empty ones.

Purge (/PURGE) Deletes destination files/directories that no longer exist in source.

Restartable (/Z) Copies files in restartable mode (resumes if network fails).

Backup Mode (/B) Copies files in backup mode (bypasses file permission restrictions).

Encrypted Raw (/EFSRAW) Copies all encrypted files in EFS RAW mode.

Attributes & Security

Copy Flags (/COPY:) Default: DAT Default (Data, Attr, Time) D - Data DA - Data, Attributes DAT - Data, Attr, Time DATS - + Security (ACLs) DATSO - + Owner Info DATSOU - All Info

Directory Flags (/DCOPY:) Default: DA Default (Data, Attr) D - Data DA - Data, Attributes DAT - + Timestamps

Copy All (/COPYALL) Copies all file information (equivalent to /COPY:DATSOU).

Copy Security (/SEC) Copies files with security (equivalent to /COPY:DATS).

Fix Security (/SECFIX) Fixes file security on all files, even skipped ones.

Add Attributes (/A+)

Remove Attributes (/A-)

Exclusion Rules

Exclude Older (/XO) Excludes older files. Does not overwrite destination if it's newer.

Exclude Newer (/XN) Excludes newer files.

Exclude Changed (/XC) Excludes changed files.

Exclude Junctions (/XJ) Excludes Junction points (soft links) for directories.

Exclude Files (/XF)

Exclude Dirs (/XD)

Size and Age

Max Size (/MAX) Bytes

Min Size (/MIN) Bytes

Max Age (/MAXAGE) Days or YYYYMMDD

Min Age (/MINAGE) Days or YYYYMMDD

Performance & Retry

Multi-Threading (/MT) 1-128 (Default 8)

Inter-Packet Gap (/IPG) ms (Slow down)

Retry Count (/R) Default 1 million

Wait Time (/W) Seconds

Live Monitoring

Run on Changes (/MON) Min changes

Check Interval (/MOT) Minutes

Run Hours (/RH) HHMM-HHMM (e.g. 2200-0600)

Log Files

**Dry Run (/L)** List only. No files will be copied or deleted.

Log Path (/LOG)

Append

Console & Log (/TEE) Outputs to console window, as well as the log file.

Output Noise

Verbose (/V)Shows skipped files.

No Progress (/NP)Don't display % progress.

No File List (/NFL)Don't log file names.

No Dir List (/NDL)Don't log directory names.

Show Timestamps (/TS)Include source file timestamps.

Show Full Path (/FP)Include full pathnames of files.

Batch Queue

Clear

Download .BAT

Queue is empty
