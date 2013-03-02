#!/usr/bin/env perl
# Takes the huge unabridged dictionary, parses it into words and their syllable counts 

keys(%words) = 100000;

open(my $dict, "<", "dict.txt") or die "Couldn't open < dict.txt!";

while (<$dict>){
  # Syllable counter:
  while ($_ =~ /<hw>(.*?)<\/hw>/g) {
    my $count = split('["`\*]', $1);
    (my $word  = $1) =~ s/["`\*\s]|<hw>//g;
    $words{lc($word)} .= " $count";
  }
}

while (($word, $count) = each(%words)) {
  print "$word$count\n";
}
