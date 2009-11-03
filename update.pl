#!/usr/bin/env perl
# Drew Stephens <drew@dinomite.net>

use strict;
use warnings;

use Carp;
use Data::Dumper;
use English '-no_match_vars';
use Getopt::Std;
use Net::Twitter;

# The bench
my @justices = (
    'FakeSouter',
    'FakeOconnor',
    'FakeSotomayor',
    'FakeBreyer',
    'FakeGinsburg',
    'FakeRoberts',
    'FakeStevens',
    'FakeKennedy',
    'FakeAlito',
    'FakeThomas',
    'FakeScalia',
);
# Other accounts
my @otherAccounts = ('FakeSCOTUS', 'fakeSCOTUSTest');

##########################  End configuration stuff  ##########################

my @accounts;
unshift @accounts, (@justices, @otherAccounts);
@accounts = map(lc, @accounts);

my $available = join "\n    ", @accounts;
my $usage =<<END
Usage: $0 <justice> all other arguments "are the status"
    $available
END
;

die $usage unless (scalar @ARGV >= 2);

# Get the account to post as
my $username = lc shift @ARGV;
# Everything else is the message
my $status = join ' ', @ARGV;

# Do we know this justice?
$username = findAccount($username);
croak "Couldn't find justice: $username " unless ($username);

# Get the password
open my $pwFile, '<', $ENV{'HOME'} . '/scotusPass'
    or croak "Couldn't read password: $OS_ERROR";
my $password = <$pwFile>;
close $pwFile;
chomp $password;

# Make a connection to Twitter
my $twitterCon = Net::Twitter->new(
    traits      => ['API::REST'],
    username    => $username,
    password    => $password,
);

# Post!
my $result = $twitterCon->update($status);

sub findAccount {
    my $username = shift;

    for my $name (@accounts) {
        if ($name =~ /((fake)?$username)/) {
            return $1;
        }
    }

    return 0;
}
