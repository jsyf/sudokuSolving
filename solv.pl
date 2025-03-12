#!/usr/bin/env perl
use strict;

my %groupCell;
my %cellGroup;
foreach my $i (0..8) {
  foreach my $j (0..8) {
    push(@{$groupCell{'Row'.$i}}, [$i, $j]);
    push(@{$cellGroup{$i.$j}}, 'Row'.$i);

    push(@{$groupCell{'Col'.$j}}, [$i, $j]);
    push(@{$cellGroup{$i.$j}}, 'Col'.$j);

    push(@{$groupCell{'Block'.int($i/3).int($j/3)}}, [$i, $j]);
    push(@{$cellGroup{$i.$j}}, 'Block'.int($i/3).int($j/3));
  }
}

my @board = &read('q.txt');
&show(\@board, 'Read:');

my $modified = 0;
@board = &scanFixed(\@board);
$modified = shift(@board);
&show(\@board, 'Scan fixed cells ('.$modified.'):');

while ($modified > 0) {
  $modified = 0;

  @board = &fixSingleCandidate(\@board);
  my $tmp = shift(@board);
  $modified += $tmp;
  &show(\@board, 'Fix single ('.$tmp.'):');
}

$modified = 999;
while ($modified > 0) {
  $modified = 0;

  @board = &fixUniqCandidate(\@board);
  my $tmp = shift(@board);
  $modified += $tmp;
  &show(\@board, 'Unique candidate ('.$tmp.'):');
}

$modified = 999;
while ($modified > 0) {
  $modified = 0;

  @board = &cleanWithNakedPair(\@board);
  my $tmp = shift(@board);
  $modified += $tmp;
  &show(\@board, 'Naked pair cleaning ('.$tmp.'):');

  @board = &fixSingleCandidate(\@board);
  my $tmp = shift(@board);
  $modified += $tmp;
  &show(\@board, 'Fix single ('.$tmp.'):');
}

$modified = 999;
while ($modified > 0) {
  $modified = 0;

  @board = &fixUniqCandidate(\@board);
  my $tmp = shift(@board);
  $modified += $tmp;
  &show(\@board, 'Unique candidate ('.$tmp.'):');
}

$modified = 999;
while ($modified > 0) {
  $modified = 0;

  @board = &cleanWithXWing(\@board);
  my $tmp = shift(@board);
  $modified += $tmp;
  &show(\@board, 'X-Wing cleaning ('.$tmp.'):');

  @board = &fixSingleCandidate(\@board);
  my $tmp = shift(@board);
  $modified += $tmp;
  &show(\@board, 'Fix single ('.$tmp.'):');
}

$modified = 999;
while ($modified > 0) {
  $modified = 0;

  @board = &fixUniqCandidate(\@board);
  my $tmp = shift(@board);
  $modified += $tmp;
  &show(\@board, 'Unique candidate ('.$tmp.'):');
}

&checkBoard(\@board);

exit;

#===== Functions

sub read {
  my $fn = shift;
  if (!-e $fn) {
    print 'File not found! Using __DATA__ '.$/;
  }

  my @res;
  my $now = '';
  #open(IN,'<'.$fn);
  while (<DATA>){
  #while (<IN>){
    chomp;
    if ($_ eq '') {
      next;
    }

    if ($_ =~ /:/) {
      $now = $`;
      next;
    }

    if ($now eq 'A') {
      last;
    }

    my @array = split("\t", $_);
    if (@array != 9){
      next;
    }

    my @row;
    for (my $i=0;$i<@array;$i++) {
      my %cell;
      if ($array[$i] =~ /^\d$/) {
        $cell{'Value'} = $array[$i];
        $cell{'Fixed'} = 1;
        $cell{'Candidate'} = {};
      }
      else {
        $cell{'Value'} = -1;
        $cell{'Fixed'} = 0;
        foreach my $j (1..9) {
          $cell{'Candidate'}{$j} = 1;
        }
      }

      push(@row, \%cell);
    }

    push(@res, \@row);
  }
  #close(IN);

  return(@res);
}

sub show {
  my @res = @{$_[0]};
  my $message = '';
  if (@_ > 1) {
    $message = $_[1];
  }

  print '====='.$/;
  if ($message ne '') {
    print $message."\n";
  }
  foreach my $i (0..8) {
    foreach my $j (0..8) {
      if ($j != 0) {print ' ';}

      printf('%2d {%17s}', $res[$i][$j]{'Value'}, join(',', (sort {$a <=> $b} (grep {$res[$i][$j]{'Candidate'}{$_} == 1} (keys %{$res[$i][$j]{'Candidate'}})))));
    }
    print "\n";
  }
  print '====='.$/;
}

sub removeCandidate { # [board], [list pos], [list remove value], [list skip pos]
  my @res = @{$_[0]};
  my @rmVal = @{$_[2]};

  my $mod = 0;

  my %pick;
  foreach my $row (@{$_[1]}) {
    $pick{$row->[0].$row->[1]} = 1;
  }
  if ((@_ > 3) && (ref($_[3]) eq 'ARRAY')) {
    foreach my $row (@{$_[3]}) {
      delete($pick{$row->[0].$row->[1]});
    }
  }

  my @pickPos;
  foreach my $row (sort{$a cmp $b} (grep {$pick{$_} == 1} (keys %pick))) {
    my @this = split('', $row);

    push(@pickPos, \@this);
  }

  undef(%pick);

  foreach my $pos (@pickPos) {
    my ($i, $j) = @{$pos};
    if ($res[$i][$j]{'Fixed'} != 1) {
      foreach my $val (@rmVal) {
        if (defined($res[$i][$j]{'Candidate'}) && defined($res[$i][$j]{'Candidate'}{$val}) && ($res[$i][$j]{'Candidate'}{$val} == 1)) {
          $res[$i][$j]{'Candidate'}{$val} = 0;
          $mod ++;
        }
      }
    }
  }

  return($mod, @res);
}

sub scanFixed {
  my @res = @{$_[0]};

  my $mod = 0;

  foreach my $i (0..8) {
    foreach my $j (0..8) {
      if ($res[$i][$j]{'Fixed'} == 1) {
        my @scanPos;
        foreach my $group (@{$cellGroup{$i.$j}}) {
          push(@scanPos, @{$groupCell{$group}});
        }

        @res = &removeCandidate(\@res, \@scanPos, [$res[$i][$j]{'Value'}]);

        my $tmp = shift(@res);
        $mod += $tmp;
      }
    }
  }

  return($mod, @res);
}

sub fixSingleCandidate {
  my @res = @{$_[0]};

  my $mod = 0;
  foreach my $i (0..8) {
    foreach my $j (0..8) {
      if ($res[$i][$j]{'Fixed'} == 1) { next; }

      my @cc = grep {$res[$i][$j]{'Candidate'}{$_} == 1} (keys %{$res[$i][$j]{'Candidate'}});

      if (@cc == 1) {
        $res[$i][$j]{'Value'} = $cc[0];
        $res[$i][$j]{'Fixed'} = 1;
        $res[$i][$j]{'Candidate'} = {};

        $mod ++;
      }
    }
  }

  @res = &scanFixed(\@res);
  my $tmp = shift(@res);
  $mod += $tmp;

  return($mod, @res);
}

sub fixUniqCandidate {
  my @res = @{$_[0]};

  my $mod = 0;

  foreach my $groupName (keys %groupCell) {
    my %countSingle;
    #my %countPattern;
    foreach my $cell (@{$groupCell{$groupName}}) {
      my ($i, $j) = @{$cell};

      foreach my $cc (grep {$res[$i][$j]{'Candidate'}{$_} == 1} (keys %{$res[$i][$j]{'Candidate'}})) {
        push(@{$countSingle{$cc}}, [$i, $j]);
      }
    }

    foreach my $cc (keys %countSingle) {
      if ((scalar @{$countSingle{$cc}}) == 1) {
        $res[$countSingle{$cc}[0][0]][$countSingle{$cc}[0][1]]{'Value'} = $cc;
        $res[$countSingle{$cc}[0][0]][$countSingle{$cc}[0][1]]{'Fixed'} = 1;
        $res[$countSingle{$cc}[0][0]][$countSingle{$cc}[0][1]]{'Candidate'} = {};

        $mod ++;
      }
    }

    @res = &scanFixed(\@res);
    my $tmp = shift(@res);
    $mod += $tmp;
  }

  return($mod, @res);
}

sub cleanWithNakedPair {
  my @res = @{$_[0]};

  my $mod = 0;

  foreach my $groupName (keys %groupCell) {
    my @allCell = @{$groupCell{$groupName}};

    my %countPattern;
    foreach my $cell (@allCell) {
      my ($i, $j) = @{$cell};

      my @cand = sort {$a <=> $b} (grep {$res[$i][$j]{'Candidate'}{$_} == 1} (keys %{$res[$i][$j]{'Candidate'}}));

      push(@{$countPattern{join('', @cand)}}, [$i, $j]);
    }

    foreach my $pattern (sort{(length($b) <=> length($a)) || ($a cmp $b)} (keys %countPattern)) {
      my @pos;

      my @allCombination;
      &patternCombination($pattern, 0, '', \@allCombination);

      foreach my $comb (@allCombination) {
        if (defined($countPattern{$comb})) {
          push(@pos, @{$countPattern{$comb}});
        }
      }

      if ((scalar @pos) != length($pattern)) {
        next;
      }

      @res = &removeCandidate(\@res, \@allCell, [split('', $pattern)], \@pos);
      my $tmp = shift(@res);
      $mod += $tmp;
    }
  }

  return($mod, @res);
}

sub patternCombination {
  my $str = shift;
  my $idx = shift;
  my $this = shift;

  my @r = @{$_[0]};

  if ($idx < length($str)) {
    foreach my $add (substr($str, $idx, 1), '') {
      &patternCombination($str, ($idx+1), $this.$add, $_[0]);
    }
  }
  elsif ($this ne '') {
    push(@{$_[0]}, $this);
  }
  else {
    return(0);
  }
}

sub cleanWithXWing {
  my @res = @{$_[0]};

  my $mod = 0;

  # for rows
  my %just2;
  foreach my $groupName (grep {$_ =~ /^Row/} (keys %groupCell)) {
    my %count;
    foreach my $cell (@{$groupCell{$groupName}}) {
      foreach my $cand (grep {$res[$cell->[0]][$cell->[1]]{'Candidate'}{$_} == 1} (keys %{$res[$cell->[0]][$cell->[1]]{'Candidate'}})) {
        push(@{$count{$cand}}, $cell);
      }
    }

    foreach my $cand (keys %count) {
      if ((scalar @{$count{$cnad}}) == 2) {
        foreach my $cell (@{$count{$cand}}) {
          $just2{$cand}{$cell->[0]}{$cell->[1]} = 1;
        }
      }
    }
  }

  
}

sub checkBoard {
  my @res = @{$_[0]};

  foreach my $groupName (sort{$a cmp $b} (keys %groupCell)) {
    my %count;
    map {$count{$_}=0} (1..9);
    foreach my $cell (@{$groupCell{$groupName}}) {
      $count{$res[$cell->[0]][$cell->[1]]{'Value'}} ++;
    }

    print 'Failed group ('.$groupName.'): '.join(', ', (map {$_.': '.$count{$_}} (grep {$count{$_} != 1} (sort{$a <=> $b} (keys %count)))))."\n";
  }
}

#class cell
#  int value
#  bool fixed
#  candidate hash
=h
Q:
3	-	-	-	-	-	-	-	-
-	-	-	7	-	5	6	-	-
-	-	-	2	1	-	-	-	3
1	-	-	-	-	-	7	-	-
-	-	-	-	-	8	3	5	-
4	-	2	-	-	-	-	-	-
-	-	9	-	8	-	-	-	-
-	-	5	-	-	-	1	4	-
-	-	-	-	6	4	-	8	-
=cut

__DATA__
Q:
-	-	-	-	-	8	5	-	-
-	-	1	-	-	-	-	-	-
4	7	3	6	-	-	-	-	-
6	-	-	2	-	-	-	-	4
-	-	-	-	-	7	-	3	-
-	-	-	-	9	5	-	6	-
-	-	-	-	-	-	-	-	6
1	-	7	-	8	-	-	-	-
-	-	8	7	-	4	-	-	-
