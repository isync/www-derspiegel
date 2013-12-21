
use lib 'lib';
use WWW::DerSpiegel;
use Data::Dumper;

die "No Issue specified! Usage for example: download.pl 31/2003" unless @ARGV;

my $obj = WWW::DerSpiegel->new;
$obj->gather($ARGV[0])->page_dedup->sort_by_page_no->as_pdf;

print Dumper($obj);
