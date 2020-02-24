#!/usr/bin/perl -w
#****************************************************************/
#  scan fiddler saz nnn_m.xml  and nnn_c.txt files 
#   to see the requests and their duration 
# 
#   redirect the output to a html file like: ./fiddlersazscan2html.pl saz/raw  > out.html
#
# (Richard Metzger, mzg@de.ibm.com, November 2014)
#****************************************************************/

use diagnostics;
use strict;
use warnings;

if (@ARGV == 0) {
   die "Input parameter (directory name containing the \"raw\" files) missing";
}

my $input = $ARGV[0];

# pseudocode
# for all *.xml files in directory
#     extract timing from XML
#     extract request from corresponding nnn_c.txt
# end

my @linebuffer = ();

opendir my $dir, $input or die "Cannot open directory: $!";
my @files = readdir $dir;
closedir $dir;

# start document and first table (in chronological order)
print "<html> <head> <style>
   table {border-collapse:collapse; table-layout:fixed; width:100%;}
   table td {border:solid 1px; word-wrap:break-word;}
   </style>
</head>
<body> 
<h1>In chronological order</h1>
<table border=\"1\" style=\"width:100%\"><tr>
<th style=\"width:3%\">Req#</th>
<th style=\"width:11%\">From</th>
<th style=\"width:11%\">to</th>
<th style=\"width:10%\">duration</th>
<th>Request</th><th>Referrer</th></tr>\n";

my $filefound=0;
foreach (sort @files) {
   my $file = $_;
   if ($file =~ /.*_m\.xml$/) {
      $filefound=1;
      #print "found: $file \n";
      # get the timings from this XML file
      my $fullfile = $input."/".$file;
      my $timestring = &gettimingsfromxml($fullfile);
      # get corresponding TXT
      $file =~ /(.*)_m\.xml/;
      my $ctxt = "$1_c.txt";
      #print "found: $file and $ctxt \n";
      $fullfile = $input."/".$ctxt;
      my $requeststring = &getrequestfromtxt($fullfile);

      # print results
      my $outline = sprintf "<tr>%s %s</tr>", $timestring, $requeststring;
      push @linebuffer, $outline;
      print "$outline\n";
   }
}
print "</table> \n";

if ($filefound==0) { die "no useful input file found  -  did you really specify the \"raw\" directory?";}

# second table (sorted on duration)
print "<h1>Sorted on duration (descending)</h1>
<table border=\"1\" style=\"width:100%\"><tr>
<th style=\"width:3%\">Req#</th>
<th style=\"width:11%\">From</th>
<th style=\"width:11%\">to</th>
<th style=\"width:10%\">duration</th>
<th>Request</th><th>Referrer</th></tr>\n";

# sort the linebuffer array
my $startduration = index($linebuffer[0], "align=\"right\">") + 14 ;
#print "\n--------------- $startduration -----------------\n";
my @sortedbuffer = sort {substr($b,$startduration,11) <=> substr($a,$startduration,11)} @linebuffer;
foreach (@sortedbuffer) { print "$_\n";}

# end of table and document
print "</table></body></html> \n";


# end main

##################################################
sub ToMillis  {
   my $intim = $_[0];
   my $millistr = substr($intim,9,6);
   $millistr =~ s/[^0-9]/0/g;  # change any non-digit char to 0
   my $millis = $millistr/1000 + 
                substr($intim,6,2)*1000 +  
                substr($intim,3,2)*1000*60 + 
                substr($intim,0,2)*1000*60*60; 
   return $millis;
}

##################################################
sub ToTimestamp  {
   my $millis = $_[0];
   my $h_after  = int($millis / 1000/60/60);
   my $m_after  = int(($millis  -  $h_after*1000*60*60) / 60 / 1000) ;
   my $s_after  = int (($millis  -  $h_after*1000*60*60 - $m_after*1000*60 ) / 1000 )  ;
   my $ms_after = $millis  -  $h_after*1000*60*60 - $m_after*1000*60  - $s_after * 1000   ;
   my $timestamp = sprintf "%02d:%02d:%02d.%03d", $h_after, $m_after, $s_after, $ms_after;
   return $timestamp;
}

##################################################
sub gettimingsfromxml  {
   my $input = $_[0];
   my $returnstring = "";
   my $line = "";

   open (INPUT,  "<$input") or die "cannot open $input for input \n";

   $input =~ /.*\/(.*)_m\.xml/;
   my $reqnum = $1;

   while (<INPUT>) {
      $line = $_;
      # raw/001_m.xml:  <SessionTimers ClientConnected="2014-11-07T20:10:08.1985333+00:00" ClientBeginRequest="2014-11-07T20:10:08.3077333+00:00" GotRequestHeaders="2014-11-07T20:10:08.3077333+00:00" ClientDoneRequest="2014-11-07T20:10:08.3077333+00:00" GatewayTime="0" DNSTime="0" TCPConnectTime="1" HTTPSHandshakeTime="0" ServerConnected="2014-11-07T20:10:08.6821333+00:00" FiddlerBeginRequest="2014-11-07T20:10:08.6821333+00:00" ServerGotRequest="2014-11-07T20:10:08.7133333+00:00" ServerBeginResponse="2014-11-07T20:10:08.7133333+00:00" GotResponseHeaders="2014-11-07T20:10:08.7133333+00:00" ServerDoneResponse="2014-11-07T20:10:08.7133333+00:00" ClientBeginResponse="2014-11-07T20:10:08.7133333+00:00" ClientDoneResponse="2014-11-07T20:10:08.7133333+00:00" />
      if ($line =~ /ClientBeginRequest=/) {
         $line =~ /ClientBeginRequest="(.*?)"/;
         my $begin = $1;
         $begin =~ s/\+//;
         $line =~ /ClientDoneResponse="(.*?)"/;
         my $done = $1;
         $done =~ s/\+//;
      
         my $btime = substr($begin, 11, 15);
         my $dtime = substr($done, 11, 15);
         my $duration = ToMillis($dtime) - ToMillis($btime);
         my $sdur = sprintf "%.3f", $duration;
         $returnstring = sprintf "<td>%s</td><td>%s</td><td>%s</td><td align=\"right\">%10s ms</td>", $reqnum, $btime, $dtime, $sdur;  
      }
   } # end while

   close INPUT;
   return $returnstring;
}
##################################################
sub getrequestfromtxt  {
   my $input = $_[0];
   my $returnstring = "";
   my $line = "";

   $input =~ /.*\/(.*)_m\.xml/;
   my $reqnum = $1;

   open (INPUT,  "<$input") or die "cannot open $input for input \n";
 
   # take request from first line
   $line = <INPUT>;
   $line =~ s/\n//;
   $line =~ s/\r//;
   $returnstring = sprintf "<td>%s</td>", $line;  

   # add referrer if there
   my $ref = "none";
   while (<INPUT>) {
      $line = $_;
      if ($line =~ /^Referer: /) {
         $line =~  /^Referer: (.*)/;
         $ref = $1;    
         $ref =~ s/\n//;
         $ref =~ s/\r//;
      }
   }
   $returnstring = sprintf "%s<td>%s</td>", $returnstring, $ref;  
   close INPUT;
   return $returnstring;
}
##################################################


__END__


