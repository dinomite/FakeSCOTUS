#!/usr/bin/env perl
# Drew Stephens <drew@dinomite.net>
#
# A script to make updating the status of a lot of Twitter accounts easy.

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
my @otherAccounts = ('FakeSCOTUS', 'FakeSCOTUSTest');

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

our $opt = {};
my $opt_string = 'c';
getopts("$opt_string", $opt) or die usage();
die getCourtMembership() if $opt->{'c'};

# No arguments, show the usage statement
unless (scalar @ARGV >= 2) {
    die usage();
}

# Get the account to post as
my $justice = lc shift @ARGV;
# Everything else is the message
my $status = join ' ', @ARGV;

# Do we know this justice?
my $username = findUsername($justice);
croak "Couldn't find justice: $justice" unless ($username);

# Make sure the status isn't too long
my $length = length $status;
die "$length characters is too much!" if ($length > 140);

# Post the update!
my $result = update($username, $password, $status);
my $statusID = $result->{'id'};

# Post that to FakeSCOTUS, too, with an @ for the original source
if ($username ne 'fakescotustest') {
    my $mirrorStatus = 'RT @'. $username .' '. $status;
    if (length $mirrorStatus > 140) {
        # Ellipsize if too long
        $mirrorStatus = (substr $mirrorStatus, 0, 139) . '…';
    }

    update('fakescotus', $password, $mirrorStatus);
}



=head3 getLastUpdateTimes(@accounts)

Get an array of accounts with their last update time.

=cut

sub getLastUpdateTimes {
    my @accounts = @_;

    my @withLast;
    foreach my $account (@accounts) {
        my $lastStatus = getLastStatus($account, $password);
        push @withLast, sprintf('        %-20s%s', $account, $lastStatus);
    }

    return @withLast;
}

=head3 findUsername($username)

Given a justice's last name, get the Twitter username.

returns Justice's Twitter useranem, or undef if none found.

=cut

sub findUsername {
    my $username = shift;

    for my $name (@accounts) {
        if ($name =~ /((fake)?$username)/) {
            return $1;
        }
    }

    return;
}

=head3 update($username, $password, $status)

Post to Twitter

=cut

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

=head3 getLastStatus($username, $password)

Get the relative time of the user's last update

=cut

sub getLastStatus {
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

=head3 getCourtMembership()

Get the membership of the court and their political leaning.

=cut

sub getCourtMembership {
    my $court =<<END
Ginsburg                            Kennedy                             Alito
Stevens                                                                 Roberts
Breyer                                                                  Scalia
Sotomayor                                                               Thomas
END
;

    return $court;
}

=head3 usage()

Get the usage statement, including the justices' last update times

=cut

sub usage {
    my $available = join "\n", getLastUpdateTimes(@accounts);
    my $usage =<<END
Usage: $0 <justice> all 'other arguments' "are the status"
        (pass -c to get political leanings)

$available
END
;

    return $usage;
}
