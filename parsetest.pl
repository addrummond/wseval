use warnings;
use strict;

use YAML::XS;

print YAML::XS::Dump(YAML::XS::LoadFile("questions.yml"));
