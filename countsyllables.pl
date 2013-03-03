#!/usr/bin/env perl
use strict;
use Net::Twitter;
use Scalar::Util 'blessed';

print "Parsing dictionary\n";
my $dict       = &dictionary_open ("syllablecount-generated.txt",
                                   "syllablecount-custom.txt");
my $suffixdict = &dictionary_open2("syllablecount-generated.txt",
                                   "syllablecount-custom.txt");
print "Parsing complete\n";


$ENV{NET_TWITTER_NO_TRENDS_WARNING}=1;
my $nt = Net::Twitter->new (
  (traits => [qw/API::Search/]));

for (my $i = 1; $i < 10; $i++) {
  my $r = $nt->search({
    q=>"pope",
    rpp=>"100",
    page=> "$i",
  });

  for my $status ( @{$r->{results}} ) {
    my $string = $status->{text};
    #Ignore tweets between two users (that is, tweets that start with @)
    if ($string =~ m/^@/){
      $personalcount++;
      next;
    }
    #Strip out hashtags at the end of tweets.
    while ($string =~ /(#\w*)$/) {
      $string =~ s/\s*#\w*$//;
    }
    #Strip out urls
    while ($string =~ /(http:\/\/\S*\b)/) {
      $string =~ s/http:\/\/\S*\b//;
    }
    my $syllables = &syllables_in_line($dict, $suffixdict, $string);
    if ($syllables ne ""){
      print "$syllables: ";
      #print "\@$status->{from_user}";
      #print "\t$status->{created_at}\n";
      print "\t\t$status->{text}\n";
      #print "-----------------------------------------------------\n";
    }
  }
}

sub syllables_in_line($$$) {
  my $s_in_line = 0;  # the 's' stands for 'syllables'
  my @words = split('[[:space:]"\?!\:\.\,#]', $_[2]);
  my $dict = $_[0];
  my $suffixdict = $_[1];
  foreach my $word (@words){
    if ($word eq "") {
      next;
    }
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

# Returns a string containing all possible syllable counts for that word as
# integers seperated by spaces. For example, "5 6 7".
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
    # Look for a suffix match. If we hit a match, remove the suffix, see if
    # the suffix-less word has a dictionary entry. If so, use that.
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
    # Inbuilt special cases failed. Try the dictionary suffixes.
    # Works the same as above, only there's more of them, and I don't agree with
    # every single one.
    # (Dictionary doesn't list any no-syllable suffixes, and there are a lot of
    # cases where the suffix doesn't actually add syllables.
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
  my %dictionary = {};
  
  foreach my $dictFile (@_) {
    print $dictFile;
    open(my $dict, "<", $dictFile)
      or die "Could not open < $dictFile!";
    while (<$dict>){
      (my $word, my $syllables) = $_ =~ /([a-z\-\\']*)(.*)/;
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
  }
  return \%dictionary;
}

# Assembles a dictionary of prefixes
sub dictionary_open2($) {
  my %dictionary = {};
  
  foreach my $dictFile (@_) {
    open(my $dict, "<", $dictFile)
      or die "Could not open < $_[0]!";
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
  }
  return \%dictionary;
}

sub dictionary_lookup ($$){
  my ($hash, $key) = @_;
  return $hash->{$key};
}
