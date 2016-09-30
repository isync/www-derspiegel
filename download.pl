#!perl

use lib 'lib';
use WWW::DerSpiegel;
use Getopt::Long;
use Cwd;

GetOptions (
	"year"		=> \my $year,
	"p|proxy=s"	=> \my $proxy,
	"user-agent=s"	=> \my $user_agent,
	"output-dir=s"	=> \my $output_dir,
	"debug"		=> \my $debug
);
if(
	(!scalar(@ARGV)) and 
	(!defined($year))
){
	die "No Issue/Year specified!\n Usage for example: download.pl 31/2003\n Or a whole year of issues into a subdir: download.pl --year 2015 --output-dir 2015 \n\n";
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
push(@options, 'proxy', $proxy) if $proxy;

my $cwd = Cwd::cwd();
print "Creating output directory $output_dir \n" if $output_dir && !-d $output_dir;
mkdir($output_dir) if $output_dir && !-d $output_dir;
chdir($output_dir) if $output_dir;
print "Changing into output directory $output_dir \n" if $output_dir;

my $obj = WWW::DerSpiegel->new(@options);
for(@issues){
	eval { $obj->gather($_)->page_dedup->sort_by_page_no->as_pdf->remove_temp_files; }; # dedup with new scraper not actually doing anything
	if($@){ print " Error gathering this issue: $@  (skipping)\n"; next; }
	sleep(2);
}

chdir($cwd) if $output_dir;

if($debug && $debug > 1){
	require Data::Dumper;
	print Data::Dumper::Dumper($obj);
}
