package WWW::DerSpiegel;

use warnings;
use strict;

use WWW::DerSpiegel::Scraper;
use LWP::UserAgent;
use Capture::Tiny;

our $VERSION = '0.04';

sub new {
	my $class = shift;

	my $self = bless({
		@_
	}, $class);

	$self->{ua} = LWP::UserAgent->new() if !$self->{ua};
	# $self->{ua}->default_header( 'User-Agent' => $self->{ua}->_agent() .'+'. __PACKAGE__ .'/'. $VERSION );
	$self->{ua}->agent( $self->{ua}->_agent() .'+'. __PACKAGE__ .'/'. $VERSION ); # no work
	print " User-Agent string is: ". $self->{ua}->agent() ."\n" if $self->{debug};

	return $self;
}

sub sort_by_page_no {
	my $self = shift;

	@{$self->{issue}->{items}} = sort { $a->{page} <=> $b->{page} } @{$self->{issue}->{items}};

	return $self;
}

sub page_dedup {
	my $self = shift;

	my %seen;
	for(@{$self->{issue}->{items}}){
		$seen{ $_->{page} } = $_;
	}

	@{$self->{issue}->{items}} = ();
	foreach(keys %seen){
		push(@{$self->{issue}->{items}}, $seen{$_} );
	}

	return $self;
}

sub as_pdf {
	my $self = shift;
	my $outfile = shift || 'DerSpiegel_'. $self->{year} .'_'. sprintf("%02d", $self->{number}) .'.pdf';

	my @files;
	my $cnt = scalar(@{$self->{issue}->{items}});
	for(@{$self->{issue}->{items}}){
		my ($file,$url);
		if($_->{jpg_link}){
			$url = $_->{jpg_link};
			$file = "/tmp/".$cnt.".jpg";
		}else{
			$url = $_->{pdf_link};
			$file = "/tmp/".$cnt.".pdf";
		}

		print " Downloading $cnt $url...";
		my $response = $self->{ua}->get( $url, ':content_file' => $file );

		print $response->is_success ? " OK\n" : " Error".$response->status_line."\n";

		if($_->{jpg_link}){
			print "  Converting cover jpg to pdf...";
			my $ps_file = $file .'.pdf';
	 		my $ok = `convert $file -compress Zip $ps_file`;
			print " OK \n";
			$file = $ps_file;
		}

		push(@files,$file);
		$cnt--;
		sleep(1); # throttle
	}

	print " Merging pages with ghostscript...";

	my ($stdout, $stderr, $exit) = Capture::Tiny::capture {
 		`gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$outfile @files`
	};
	if($exit){ # gs exits with undef on ok
		print " Error: gs exit code:$exit, stderr:$stderr\n";
	}else{
		print " OK\n";
		print "Issue ". $self->{number} .'/'. $self->{year} ." saved as $outfile\n";
	}

	print "gs exit code:".($exit||'').", stdout:". length($stdout) .", stderr:". length($stderr) ."\n" if $self->{debug};
}

sub gather {
	my $self = shift;

	my $magazine = shift;

	($self->{number},$self->{year}) = split(/\//,$magazine);

	die "Output pdf exists!" if -f 'DerSpiegel_'. $self->{year} .'_'. sprintf("%02d", $self->{number}) .'.pdf' && !$self->{force};

	die "gather: year or number missing!" unless $self->{number} && $self->{year};
	print "gather: GET ". 'http://www.spiegel.de/spiegel/print/index-'. $self->{year} .'-'. $self->{number} .'.html' ."\n" if $self->{debug};

	print "Downloading issue ". $self->{year} .'-'. $self->{number} ." toc...";
	my $response = $self->{ua}->get('http://www.spiegel.de/spiegel/print/index-'. $self->{year} .'-'. $self->{number} .'.html');
	die $response->status_line if !$response->is_success;
	print " OK\n";

	$self->{issue} = WWW::DerSpiegel::Scraper::new_index_scrape($response->decoded_content);

	for(@{$self->{issue}->{items}}){
		die "This issue is not yet available for free. Wait a few weeks more." if $_->{article_link} =~ /utm_source/;
	}

	unless($response->decoded_content =~ />Titelbild<\/h3>/){
		print " This issue has no cover pdf. Adding jpeg instead.\n";
		unshift(@{$self->{issue}->{items}}, {
			jpg_link => 'http://magazin.spiegel.de/EpubDelivery/image/title/SP/'. $self->{year} .'/'. $self->{number} .'/800', # -1200
			page => 0
		});
	}

	my $cnt = scalar(@{ $self->{issue}->{items} });

	return $self;
}

=pod

=head1 NAME

WWW::DerSpiegel - "Der SPIEGEL" magazine archive pseudo API

=head1 SYNOPSIS

	use WWW::DerSpiegel;
	my $wi = WWW::DerSpiegel->new();


=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

isync

=head1 COPYRIGHT

Copyright 2013/2015 isync. All rights reserved.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut
