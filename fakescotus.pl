#!/usr/bin/env perl
# Drew Stephens <drew@dinomite.net>

use strict;
use warnings;

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

# Get the password
open my $pwFile, '<', '~/scotusPass'
    or croak "Couldn't read password: $OS_ERROR";
my $password = <$pwFile>;
close $pwFile;



my @accounts;
unshift @accounts, (@justices, @otherAccounts);



my $twitter = Net::Twitter->new(
    traits      => ['API::REST'],
    username    => 'fakescotustest',
    password    => $password,
);

my $result = $twitter->update("Hola, worldo!");
