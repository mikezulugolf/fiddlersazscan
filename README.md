# fiddlersazscan
## Purpose
This script takes a Fiddler SAZ trace and converts it into a simpler text-only format suitable for filtering and sorting with command line utilities like "grep", "sort", "uniq", and the like
## Usage
1. unpack the .saz file (it is nothing else than a .zip file) into a separate subdirectory
2. run:  fiddlersazscan.pl the-name-of-the above-subdirectory  >  output.txt
3. and have a look at the result:

        request 001 from=14:37:43.062633 to=14:37:43.249826 duration=    187.193 ms GET http://xxxxxxxx 
        request 002 from=14:37:43.281025 to=14:37:43.312223 duration=     31.198 ms GET http://www.xxxxxxxxxxxxx
        request 003 from=14:37:43.327823 to=14:37:43.733407 duration=    405.584 ms GET http://www.xxxxxxx
        request 004 from=14:37:59.254810 to=14:37:59.364006 duration=    109.196 ms CONNECT srvxxxxxxx.xxxx:9444 xxxx
        request 005 from=14:38:02.546284 to=14:38:32.575129 duration=  30028.845 ms POST https://srvxxxxxx
        request 006 from=14:38:28.269694 to=14:38:28.285294 duration=     15.600 ms CONNECT srvxxxxxxxxx
        request 007 from=14:38:28.316492 to=14:38:28.347691 duration=     31.199 ms GET https://srvxxxxx/rest/blablabla
        request 008 from=14:38:28.332092 to=14:38:28.347691 duration=     15.599 ms CONNECT srvxxxxxxxx
        ....

A simple "sort -n -r -k 6 output.txt | head -20" tells you the top 20 of the recorded requests.

I hope you find it as useful in problem determination as several of my support colleagues did.


# fiddlersazscan2html
## Purpose
as above, but produces HTML output
