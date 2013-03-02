#!/usr/bin/env perl
use strict;

my $dict       = &dictionary_open("syllablecount.txt");
my $suffixdict = &dictionary_open2("syllablecount.txt");

# foreach my $key (keys %$suffixdict) {
   # print "\n$key"; # $suffixdict->{$key}
# }

my @phrases = (
  "What's up",
  "What's",
  "WhAT",
  "up",
  "WhAt's up?!",
  "is am were was",
  "am",
  "amgerous");
foreach my $phrase (@phrases) {
  print "\"$phrase\": " . &syllables_in_line($dict, $suffixdict, $phrase) . "\n";
}
print "What: " . &syllables_in_word($dict, $suffixdict, "What") . "\n";
print "up: " . &syllables_in_word($dict, $suffixdict, "up") . "\n";
print "oid: " . &syllables_in_word($suffixdict, $suffixdict, "oid") . "\n";

# Returns a string containing all possible syllable counts for the given line 
sub syllables_in_line($$$) {
  my $s_in_line = 0;  # the 's' stands for 'syllables'
  my @words = split('[[:space:]"\?!\:]', $_[2]);
  my $dict = $_[0];
  my $suffixdict = $_[1];
  foreach my $word (@words){
    my $s_in_word = syllables_in_word($dict, $suffixdict, $word);
    my $new_s_in_line = "";
    
    # This nested for-loop adds each integer in the space-delineated string
    # returned by syllables_in_word to each integer in the space-delineated
    # string $s_in_line. Result will be another string of integers seperated by
    # spaces.
    (my @s_iter) = $s_in_word =~ /\d+/g;
    foreach my $n (@s_iter) {
      (my @s_iter_2) = $s_in_line =~ /\d+/g;
      foreach my $m (@s_iter_2) {
        $m += $n;
        if ($new_s_in_line !~ / $m /) {
          $new_s_in_line .= " $m ";
        }
      }
    }
    $s_in_line = $new_s_in_line;
  }
  return $s_in_line;
}

# Returns a string containing all possible syllable counts for that word
sub syllables_in_word($$$) {
  my $word = lc $_[2];
  my $suffixdict = $_[1];
  my $word_count = dictionary_lookup($_[0], $word);
  
  if($word_count eq ""){
    # Counter failed.  Special cases?
    # Make sure you keep this falling order of specificity (check for "es"
    # before you check for "s", etc).
    my %suffixes = (
      'ing'  => 1,
      'e\'s' => 1,
      '\'s'  => 0,
      'es'   => 1,
      's'    => 0,
      'ed'   => 0,
      'en'   => 1
    );
    foreach my $key (keys %suffixes) {
      if ($word =~ m/$key$/) {
        my $tempword = $word;
        $/ = $key;
        chomp $tempword;
        $word_count = dictionary_lookup($_[0], $tempword);
        
        # Add the suffix syllable count
        (my @s_iter) = $word_count =~ /\d+/g;
        my $new_word_count;
        foreach my $n (@s_iter) {          
            my $m = $n + $suffixes{$key};
            if ($new_word_count !~ / $m /) {
              $new_word_count .= " $m ";
            }
        }
        $word_count = $new_word_count;
      }
      if ($word_count ne "") {
        last;
      }
    }
  }
  if($word_count eq ""){
    foreach my $key (keys %$suffixdict) {
      if ($word =~ m/$key$/) {
        my $tempword = $word;
        $/ = $key;
        chomp $tempword;
        
        $word_count = dictionary_lookup($_[0], $tempword);
        my $suffix_syllables = dictionary_lookup($_[1], $key);
        
        # Add the suffix syllable count
        (my @s_iter) = $word_count =~ /\d+/g;
        my $new_word_count;
        foreach my $n (@s_iter) {          
            my $m = $n + $suffix_syllables;
            if ($new_word_count !~ / $m /) {
              $new_word_count .= " $m ";
            }
        }
        $word_count = $new_word_count;
      }
      if ($word_count ne ""){
        last;
      }
    }
  }

  return $word_count;
}

sub dictionary_open($) {
  open(my $dict, "<", $_[0])
    or die "Could not open < $_[0]!";
  my %dictionary = {};
  while (<$dict>){
    (my $word, my $syllables) = $_ =~ /([a-z\-\\]*)(.*)/;
    if (!($word =~ m/^\-/)) {
      # Remove duplicates
      (my @s_iter) = $syllables =~ /\d+/g;
      my $new_syllables;
      foreach my $n (@s_iter) {          
        if ($new_syllables !~ / $n /) {
          $new_syllables .= " $n ";
        }
      }
      $dictionary{$word} = $new_syllables;
    }
  }
  return \%dictionary;
}

# Assembles a dictionary of prefixes
sub dictionary_open2($) {
  open(my $dict, "<", $_[0])
    or die "Could not open < $_[0]!";
  my %dictionary = {};
  while (<$dict>){
    (my $word, my $syllables) = $_ =~ /([a-z\-\\]*)(.*)/;
    if ($word =~ m/^\-/) {      
      # Remove duplicates
      (my @s_iter) = $syllables =~ /\d+/g;
      my $new_syllables;
      foreach my $n (@s_iter) {          
        if ($new_syllables !~ / $n /) {
          $new_syllables .= " $n ";
        }
      }
      
      $dictionary{substr($word, 1)} = $new_syllables;
    }
  }
  return \%dictionary;
}

sub dictionary_lookup ($$){
  my ($hash, $key) = @_;
  return $hash->{$key};
}
