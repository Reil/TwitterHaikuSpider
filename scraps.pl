#!/usr/bin/env perl
$string = "fucking";
    my %suffixes = (
      'ing'  => 1,
      'es'   => 2,
      's'    => 0,
      'ed'   => 0,
      'en'   => 1,
      'e\'s' => 1,
      '\'s'  => 0
    );
    foreach my $key (keys %suffixes) {
      print "\n$key $suffixes{$key}";
      if ( $string =~ m/$key$/) {
        print "$string";
      }
    }
    
    $egg = $string;
    $/ = "ing";
    chomp $egg;
    print $egg;