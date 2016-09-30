WWW::DerSpiegel
===============

WWW::DerSpiegel - "Der SPIEGEL" magazine archive pseudo API and download

## SYNOPSIS

	use WWW::DerSpiegel;
	my $wi = WWW::DerSpiegel->new();

## BESCHREIBUNG

Das Deutsche Nachrichtenmagazin "Der Spiegel" veröffentlicht seine älteren Ausgaben
regelmäßig nach 6 Monaten im Heftarchiv. Allerdings in zerpflückter Weise: ein PDF
pro Artikel. Dieses Modul hier greift programmatisch auf die Artikel zu und hilft, 
einzelne Ausgaben als ganze PDF Dateien wieder zusammen zu setzen.

WWW::DerSpiegel verwendet die Linux tools _gs_ und ImageMagicks _convert_.

## DESCRIPTION

The German news magazine "Der Spiegel" publishes back-issues (after 6 months) as
free for everyone on website, in the archive section. This module here accesses
this archive in a programmatical manner and is able to compile issues as pdf files.

WWW::DerSpiegel relies on Linux tools _gs_ and ImageMagick's _convert_.

Usage:

The bundled download.pl script uses the WWW::DerSpiegel module to download single
issues issues or a whole year. For example:

	$ perl download.pl 31/2003
	$ perl download.pl --year 2015 --output-dir 2015

## Hey, contribute!

If you find this useful, help making this a working module again. Fork this repo
and contribute your changes!

## Note

This module is not a complete CPAN bundle, and will remain this way.
