package WWW::DerSpiegel;

use warnings;
use strict;

use WWW::DerSpiegel::Scraper;
use LWP::UserAgent;

our $VERSION = '0.03';

sub new {
	my $class = shift;

	my $self = bless({
		@_
	}, $class);

	$self->{ua} = LWP::UserAgent->new( agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.1 (KHTML, like Gecko) Chrome/22.0.1207.1 Safari/537.1 HTTP_ACCEPT: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8' ) if !$self->{ua};

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
	my $outfile = shift || 'DerSpiegel_'. $self->{year} .'_'. $self->{number} .'.pdf';

	my @files;
	my $cnt = scalar(@{$self->{issue}->{items}});
	for(@{$self->{issue}->{items}}){
		print " Downloading $cnt $_->{pdf_link}...";

		my $file = "/tmp/".scalar(@files).".pdf";
		my $response = $self->{ua}->get( $_->{pdf_link}, ':content_file' => $file );

		print $response->is_success ? " OK\n" : " Error".$response->status_line."\n";

		push(@files,$file);
		$cnt--;
	}

	my $ok = `gs -dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=$outfile @files`;
}

sub gather {
	my $self = shift;

	my $magazine = shift;

	($self->{number},$self->{year}) = split(/\//,$magazine);

	die "gather: year or number missing!" unless $self->{number} && $self->{year};
	print "gather: GET ". 'http://www.spiegel.de/spiegel/print/index-'. $self->{year} .'-'. $self->{number} .'.html' ."\n" if $self->{debug};

	print "Downloading issue ". $self->{year} .'-'. $self->{number} ." toc...";
	my $response = $self->{ua}->get('http://www.spiegel.de/spiegel/print/index-'. $self->{year} .'-'. $self->{number} .'.html');
	die $response->status_line if !$response->is_success;
	print " OK\n";

	$self->{issue} = WWW::DerSpiegel::Scraper::new_index_scrape($response->decoded_content);

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
