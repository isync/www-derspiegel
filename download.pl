
use lib 'lib';
use WWW::DerSpiegel;
# use Data::Dumper;
use Getopt::Long;

GetOptions (
	"year"	=> \my $year
);
if (  (!scalar(@ARGV)) and 
	(!defined($year))
    ){
die "No Issue/Year specified! Usage for example: download.pl 31/2003\n";
}

my @issues;
if($year){
	for(1..52){ push(@issues, $_ .'/'. $ARGV[0]); }
}else{
	@issues = @ARGV;
}

my $obj = WWW::DerSpiegel->new();
for(@issues){
	$obj->gather($_)->page_dedup->sort_by_page_no->as_pdf;
	sleep(2);
}

# print Dumper($obj);
