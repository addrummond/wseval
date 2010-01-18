#!/usr/bin/perl
use warnings;
use strict;

use CGI;
use Template;
use JSON::XS;
use YAML::XS;

my $questions = YAML::XS::LoadFile("questions.yml") or die "Unable to load questions.yml: $!";

my $q = CGI->new;

print $q->header(
    -type    => 'text/html', # Anything else might confuse poor old IE 6.
    -status  => '200 OK',
    -charset => 'UTF-8'
);

my $encoded_questions = JSON::XS::encode_json($questions);
my $tt = Template->new();

my @stats = stat('main.tt');
my @cstats = stat('main.tt.cache');

if (! -f 'main.tt.cache' || $cstats[9] < $stats[9]) {
    open my $cache, '>main.tt.cache' or die "Unable to open cache file: $!";
    $tt->process("main.tt", { questions => $encoded_questions }, $cache);
    close $cache or die "Unable to close cache file: $!";
    open my $cacher, 'main.tt.cache' or die "Unable to open cache file (2): $!";
    for (<$cacher>) { print; }
    close $cacher or die "Unable to close cache file (2): $!";
}
else {
    open my $cache, 'main.tt.cache' or die "Unable to open cache file (3): $!";
    for (<$cache>) { print; }
    close $cache or die "Unable to close cache file (3): $!";
}

