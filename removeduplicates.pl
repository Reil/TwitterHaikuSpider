use Data::Compare;
use Storable;
use Storable qw(nstore);

if ($#ARGV == -1) {
  die("No filename given.");
}

my @removeDupes;
if (-e @ARGV[0]) {
  @removeDupes = @{retrieve("@ARGV[0]")};
} else {
  print "File does not exist. \n";
}
print("Original Size: $#removeDupes\n");

my @noDupes;
foreach $insertMe (@removeDupes) {
  my $dontInsert = 0;
  foreach $compareMe(@noDupes) {
    if (Compare($insertMe, $compareMe)) {
      $dontInsert = 1;
      last;
    }
  }
  if ($dontInsert == 0) {
    push(@noDupes, $insertMe);
  }
}
print("New Size: $#noDupes\n");

nstore(\@noDupes, @ARGV[0]);