#!/usr/bin/perl
use warnings;
use strict;

use CGI;
use JSON::XS;
use File::Spec::Functions qw( catfile );

use constant RESULTS_DIR => "/var/ws2010results";

my $q = CGI->new;

sub bad_req {
    my $e = shift;
    print $q->header(
        -type => 'text/json',
        -status => '400 Bad Request',
        -charset => 'UTF-8'
    );
    print JSON::XS::encode_json({ error => $e }), "\n";
    exit 0;
}

if (! $q->param('responses')) {
    bad_req "No 'responses' paramater";
}

my $responses = JSON::XS::decode_json($q->param('responses'));
if (! $responses || ref($responses) ne "ARRAY") {
    bad_req "Bad 'responses' paramater";
}

my $fname = "r" . time;
my $max = 0;
while (-f catfile(RESULTS_DIR, "$fname.txt")) {
    $fname .= '-1';
    ++$max;
    die "Can't get file name" if ($max > 100);
}
$fname .= ".txt";

open my $r, ">>" . catfile(RESULTS_DIR, $fname) or die "Couldn't open results file: $!";
print $r $q->param('responses'), "\n";
close $r or die "Couldn't close results file: $!";

print $q->header(
    -type => 'text/json',
    -status => '200 OK',
    -charset => 'UTF-8'
);
print "null\n";
