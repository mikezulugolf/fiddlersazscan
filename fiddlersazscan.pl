#!/usr/bin/perl -w

#****************************************************************/
#  scan fiddler saz nnn_m.xml  and nnn_c.txt files
# 
#   to see the requests and their duration 
#
#****************************************************************/

use diagnostics;
use strict;
use warnings;
#use Text::Balanced qw/extract_multiple extract_bracketed/;

if (@ARGV == 0) {
   die "Input parameter (directory name containing the \"raw\" files) missing";
}

my $input = $ARGV[0];

#open (INPUT,  "<$input") or die "cannot open $input for input \n";

# pseudocode
# for all *.xml files in directory
#     extract timing from XML
#     extract request from corresponding nnn_c.txt
# end

opendir my $dir, $input or die "Cannot open directory \"$input\" : $!";
my @files = readdir $dir;
closedir $dir;

my $filefound=0;
foreach (sort @files) {
   my $file = $_;
   #print "found: $file \n";
   if ($file =~ /.*_m\.xml$/) {
      $filefound=1;
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
      print "$timestring $requeststring \n";
   }
}

if ($filefound==0) { die "no useful input file found  -  did you really specify the \"raw\" directory?";}


##################################################
sub ToMillis  {
   my $intim = $_[0];
   #print "----------->$intim<--------\n";
   if (length($intim)<9) { $intim = "$intim.000000";}  #sometimes the ms aren't there like in ClientDoneResponse="0001-01-01T00:00:00" 
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
         $line =~ /ClientBeginRequest=\"(.*?)\"/;
         my $begin = $1;
         $line =~ /ClientDoneResponse=\"(.*?)\"/;
         my $done = $1;
         #print "--->$begin  $done\n";
         my $btime = substr($begin, 11, 15);
         my $dtime = substr($done, 11, 15);
         my $duration = ToMillis($dtime) - ToMillis($btime);
         my $sdur = sprintf "%.3f", $duration;
         $returnstring = sprintf "request %s from=%s to=%s duration= %10s ms", $reqnum, $btime, $dtime, $sdur;  
         #print "--->$returnstring\n";
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
   $returnstring = sprintf "%s", $line;  

   # add referrer if there
   while (<INPUT>) {
      $line = $_;
      if ($line =~ /^Referer: /) {
         $line =~ s/\n//;
         $line =~ s/\r//;
         $returnstring = sprintf "%s %s", $returnstring, $line;  
      }
   }

   close INPUT;
   return $returnstring;
}
##################################################





__END__







