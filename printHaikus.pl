#!/usr/bin/env perl

use strict;
use Storable;
use Storable qw(nstore);

no warnings 'utf8';

my $search = @ARGV[0];
open STDOUT, '>', $search . "haikus.html";

my @syllables5;
my @syllables7;
if (-e $search."5.txt" && -e $search."7.txt") {
  @syllables5 = @{retrieve($search . "5.txt")};
  @syllables7 = @{retrieve($search . "7.txt")};
} else {
  die("Missing a required file.");
}


print "<h1>Five Syllables</h1>\n";
foreach my $line (@syllables5) {
  print "<p><a href=\"http://twitter.com/" . $line->{"from_user"} .
         "/status/" . $line->{"id"} .
         "\" title=\"Tweet by " . $line->{"from_user"} .
         " on " . $line->{"created_at"} . "\">" . 
         $line->{"text"} .
         "</a></p>\n";
}


print "<br><br><br><h1>Seven Syllables</h1>\n";

foreach my $line (@syllables7) {
  print "<p><a href=\"http://twitter.com/" . $line->{"from_user"} .
         "/status/" . $line->{"id"} .
         "\" title=\"Tweet by " . $line->{"from_user"} .
         " on " . $line->{"created_at"} . "\">" . 
         $line->{"text"} .
         "</a></p>\n";
}