#!/usr/bin/env perl
# Drew Stephens <drew@dinomite.net>

use strict;
use warnings;

use Carp;
use Data::Dumper;
use DateTime;
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

# Get the password
open my $pwFile, '<', $ENV{'HOME'} . '/scotusPass'
    or croak "Couldn't read password: $OS_ERROR";
my $password = <$pwFile>;
close $pwFile;
chomp $password;

my @accounts;
unshift @accounts, (@justices, @otherAccounts);
@accounts = map(lc, @accounts);

unless (scalar @ARGV >= 2) {
    # Create an array with the last time the justice had an update
    my @withLast = map(sprintf('    %-20s%s', $_, lastStatus($_, $password)), @accounts);
    my $available = join "\n    ", @withLast;
    my $usage =<<END
Usage: $0 <justice> all other arguments "are the status"
    $available
END
    ;

    die $usage;
}

# Get the account to post as
my $username = lc shift @ARGV;
# Everything else is the message
my $status = join ' ', @ARGV;

# Do we know this justice?
$username = findAccount($username);
croak "Couldn't find justice: $username " unless ($username);

my $length = length $status;
die "$length characters is too much!" if ($length > 140);

# Post!
my $result = update($username, $password, $status);
my $statusID = $result->{'id'};

# Post that to FakeSCOTUS, too, with an @ for the original source
if ($username ne 'fakescotustest') {
    my $mirrorStatus = 'RT @'. $username .' '. $status;
    if (length $mirrorStatus > 140) {
        # Ellipsize if too long
        $mirrorStatus = (substr $mirrorStatus, 0, 139) . '…';
    }

    update('fakescotus', $password, $statusID);
}

sub findAccount {
    my $username = shift;

    for my $name (@accounts) {
        if ($name =~ /((fake)?$username)/) {
            return $1;
        }
    }

    return 0;
}

sub update {
    my ($username, $password, $status) = @_;

    # Make a connection to Twitter
    my $twitterCon = Net::Twitter->new(
        traits      => ['API::REST'],
        username    => $username,
        password    => $password,
    );

    return $twitterCon->update($status);
}

# Get the relative time of the user's last update
sub lastStatus {
    my ($username, $password) = @_;

    # Make a connection to Twitter
    my $twitterCon = Net::Twitter->new(
        traits      => ['API::REST', 'InflateObjects'],
        username    => $username,
        password    => $password,
    );

    my $info = $twitterCon->show_user($username);
    if (defined $info->{'status'}) {
        return $info->{'status'}->relative_created_at();
    } else {
        return '';
    }
}
