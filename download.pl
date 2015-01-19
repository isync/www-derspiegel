#!perl

use lib 'lib';
use WWW::DerSpiegel;
use Getopt::Long;

GetOptions (
	"year"		=> \my $year,
	"user-agent=s"	=> \my $user_agent,
	"debug"		=> \my $debug
);
if(
	(!scalar(@ARGV)) and 
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

my @options;
push(@options, 'debug', $debug) if $debug;
push(@options, 'user_agent', $user_agent) if $user_agent;

my $obj = WWW::DerSpiegel->new(@options);
for(@issues){
	eval { $obj->gather($_)->page_dedup->sort_by_page_no->as_pdf; };
	if($@){ print " Error gathering this issue: $@  (skipping)\n"; next; }
	sleep(2);
}

if($debug && $debug > 1){
	require Data::Dumper;
	print Data::Dumper::Dumper($obj);
}
