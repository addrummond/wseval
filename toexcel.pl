use warnings;
use strict;

use JSON::XS;
use Spreadsheet::WriteExcel;
use File::Spec::Functions qw( catfile );

use constant RESULTS_DIR => '/var/ws2010results';

my $ofname = "results.xls";
my $tofname = "results.txt";

sub getcoltitle {
    my $r = shift;
    return (join '/', @{$r->[0]}) . ':' . $r->[1];
}

my $workbook = Spreadsheet::WriteExcel->new($ofname);
my $worksheet = $workbook->add_worksheet();

open my $tf, ">$tofname" or die "Unable to open '$tofname': $!";

my $boldf = $workbook->add_format();
$boldf->set_bold;

opendir my $dir, RESULTS_DIR or die "Unable to open results dir: $!";
my $current_row = 0;
my @column_titles;
while (my $entry = readdir($dir)) {
    next if $entry =~ /^\./;

    my $fname = catfile(RESULTS_DIR, $entry);
    open my $fh, $fname or die "Unable to open results file '$fname' for reading: $!";

    local $/;
    my $contents = <$fh>;
    my $json = JSON::XS::decode_json($contents) or die "Bad results file '$fname'";

    if ($current_row == 0) {
        # Get column titles.
        @column_titles = map { getcoltitle $_ } @$json;
        my $ccol = 0;
        for my $title (@column_titles) {
            $worksheet->write(0, $ccol++, $title, $boldf);
        }
        ++$current_row;
    }
    else {
        # Check that the column titles are the same (otherwise we can't merge these
        # into the same excel file).
        my @new_column_titles = map { getcoltitle $_ } @$json;
        #use YAML::XS;
        #print "In new, not in old:", (YAML::XS::Dump([ grep { my $i = $_; ! grep { $_ eq $i } @new_column_titles } @column_titles ]));
        #print "\n\nIn old, now in new:", (YAML::XS::Dump([ grep { my $i = $_; ! grep { $_ eq $i } @column_titles } @new_column_titles]));
        #print "\n\n", scalar(@new_column_titles), " ", scalar(@column_titles), "\n\n";
        #print YAML::XS::Dump(@new_column_titles), "\n\n", YAML::XS::Dump(@column_titles);
        die "Unable to merge (1)" if scalar(@new_column_titles) != scalar(@column_titles);
        for (my $i = 0; $i < scalar(@new_column_titles); ++$i) {
            die "Unable to merge (2)" if ($new_column_titles[$i] ne $column_titles[$i]);
        }
    }

    my $current_column = 0;
    for my $question (@$json) {
        my $ans = $question->[2];
        $ans =~ s/\n/\r\n/g if ($ans);

        # EXCEL.
        if ($ans) {
            if ($ans =~ /^\d+$/) {
                $worksheet->write_number($current_row, $current_column, $ans);
            }
            else {
                $worksheet->write_string($current_row, $current_column, $ans);
            }
        }

        # PLAIN TEXT
        print $tf "- ", $column_titles[$current_column], "\n", ($ans || ""), "\n\n";

        ++$current_column;
    }

    close $fh or die "Unable to close results file '$fname': $!";

    ++$current_row;
}
closedir $dir or die "Unable to close results dir: $!";

$workbook->close();
close $tf or die "Unable to close '$tofname': $!";
