package WWW::DerSpiegel;

use warnings;
use strict;

use WWW::DerSpiegel::Scraper;
use LWP::UserAgent;

our $VERSION = '0.01';

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

	@{$self->{issue}->{items}} = sort { $a->{page_no} <=> $b->{page_no} } @{$self->{issue}->{items}};

	return $self;
}

sub page_dedup {
	my $self = shift;

	my %seen;
	for(@{$self->{issue}->{items}}){
		$seen{ $_->{page_no} } = $_;
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

	my $response = $self->{ua}->get('http://www.spiegel.de/spiegel/print/index-'. $self->{year} .'-'. $self->{number} .'.html');
	die $response->status_line if !$response->is_success;

	$self->{issue} = WWW::DerSpiegel::Scraper::index_scrape($response->decoded_content);

	my $cnt = scalar(@{$self->{issue}->{items}});
	for(@{$self->{issue}->{items}}){
		next if !$_->{article_link};

		print " GET $cnt $_->{article_link}...";
		$response = $self->{ua}->get( $_->{article_link} );
		if($response->is_success){ print " OK\n" }else{ print " Error\n"; };

		my $ameta = WWW::DerSpiegel::Scraper::article_scrape($response->decoded_content);

		$_->{pdf_link} = $ameta->{pdf_link};
		print " No PDF link!\n" if !$_->{pdf_link};

	#	$_->{pdf_link} = 'http://wissen.spiegel.de/wissen/image/show.html?did='
	#			. $_->{document_id}
	#			.'&aref='
	#			. $ameta->{imagebit}
	#			. '/ROSP'. $year. sprintf("%03d", $issue) . sprintf("%03d", $issue) . sprintf("%03d", $issue)
	#									^^^ 			^^^ from-to pages is not predicatable, so we have to crawl all articles..
	#			.'.PDF&thumb=false',
		$cnt--;
	}

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

Copyright 2013 isync. All rights reserved.

=head1 LICENSE

This library is free software. You can redistribute it and/or modify it under the same terms as Perl itself.

=cut