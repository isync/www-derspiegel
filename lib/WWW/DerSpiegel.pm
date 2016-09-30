package WWW::DerSpiegel;

use warnings;
use strict;

use WWW::DerSpiegel::Scraper;
use LWP::UserAgent;
use Capture::Tiny;

our $VERSION = '0.05';

sub new {
	my $class = shift;

	my $self = bless({
		@_
	}, $class);

	$self->{ua} = LWP::UserAgent->new(agent => "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36") if !$self->{ua};
	# $self->{ua}->default_header( 'User-Agent' => $self->{ua}->_agent() .'+'. __PACKAGE__ .'/'. $VERSION );
	# $self->{ua}->agent( $self->{ua}->_agent() .'+'. __PACKAGE__ .'/'. $VERSION ); # no work
	print " User-Agent string is: ". $self->{ua}->agent() ."\n" if $self->{debug};

	if($self->{proxy}){
		$self->{ua}->proxy(['http','https'] => $self->{proxy});
		print " Using proxy $self->{proxy} \n" if $self->{debug};
	}

	return $self;
}

sub sort_by_page_no {
	my $self = shift;

	@{$self->{issue}->{items}} = sort { $a->{page} <=> $b->{page} } @{$self->{issue}->{items}};

	return $self;
}

# currently unused:
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
			$file = '/tmp/'. $self->{year} . $self->{number} . $cnt .".jpg";
		}else{
			$url = $_->{pdf_link};
			$file = '/tmp/'. $self->{year} . $self->{number} . $cnt .".pdf";
		}

		print " Downloading $cnt $url...";
		my $response = $self->{ua}->get( $url, ':content_file' => $file );

		if($response->is_success){
			print " OK\n";
			$_->{download_ok} = 1;
		}else{
			print " Error: ". $response->status_line."\n";
		}

		if($_->{jpg_link}){
			print "  Converting cover jpg to pdf...";
			my $ps_file = $file .'.pdf';
	 		my $ok = `convert $file -compress Zip $ps_file`;
			print " OK \n";
			$file = $ps_file;
		}

		$cnt--;

		next unless $_->{jpg_link} or $_->{download_ok}; # no push, prevent gs from error

		push(@files,$file);
		sleep(1); # throttle
	}

	push(@{ $self->{temp_files} }, @files);

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

	return $self;
}

sub remove_temp_files {
	my $self = shift;

	for my $temp_file (@{ $self->{temp_files} }){
		print "removing temp file $temp_file ... " if $self->{debug};
		my $ok = unlink($temp_file);
		if($self->{debug}){
			if($ok){ print "OK\n"; }else{ print "Error removing $temp_file: $!\n"; }
		}
	}
	@{ $self->{temp_files} } = ();

	return $self;
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

	$self->{issue} = WWW::DerSpiegel::Scraper::new_2015_index_scrape($response->decoded_content);

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

WWW::DerSpiegel - "Der SPIEGEL" magazine archive pseudo API and download

=head1 SYNOPSIS

	use WWW::DerSpiegel;
	my $wi = WWW::DerSpiegel->new();


=head1 DESCRIPTION

=head1 METHODS

=head1 AUTHOR

isync

=head1 COPYRIGHT

Copyright 2013/2016 isync. All rights reserved.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut
