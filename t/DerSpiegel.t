#!perl -w

use File::Slurp;
use Data::Dumper;
use Test::More;
use Test::Deep;
use Encode;

use lib 'lib';
use WWW::DerSpiegel;

plan tests => 5;


my $html = decode_utf8( File::Slurp::read_file('t/data/spiegel.de_spiegel_print_index-2003-48.html') );

my $meta = WWW::DerSpiegel::Scraper::new_index_scrape( $html );

my ($has_title,$is_numeric,$has_url,$pdf_ok) = (1,1,1,1);
for my $toc_entry (@{$meta->{items}}){
	$has_title = 0 if !$toc_entry->{text} || length($toc_entry->{text}) < 3;
	$is_numeric = 0 if !$toc_entry->{page} || $toc_entry->{page} !~ /\d+/;
	$has_url = 0 if !$toc_entry->{article_link} || $toc_entry->{article_link} !~ /page/;
	$pdf_link = 0 if !$toc_entry->{pdf_link} || $toc_entry->{pdf_link} !~ /\d+/;
}

ok($has_title && $is_numeric && $has_url && $pdf_ok, 'canned toc scrape looks sane');



my $html = decode_utf8( File::Slurp::read_file('t/data/spiegel.de_spiegel_print_index-2003-48_article.html') );

my $meta = WWW::DerSpiegel::Scraper::new_article_scrape( $html );

is($meta->{pdf_link}, 'http://magazin.spiegel.de/EpubDelivery/spiegel/pdf/29274027', 'canned article scrape ok');



my $html = decode_utf8( File::Slurp::read_file('t/data/spiegel.de_spiegel_print_index-2003-31.html') );

my $meta = WWW::DerSpiegel::Scraper::index_scrape( $html );


cmp_deeply($meta, {
	'cover' => 'http://wissen.spiegel.de/wissen/titel/SP/2003/31/300/titel.jpg',
	'cover_width' => '300',
	'heft' => 'Heft 31/2003',
	'items' => [
                       {
                         'no_class' => ' class="spHeftInhaltNoPageNumber"',
                         'cat' => 'Titel',
                         'has_cat' => 1,
                         'title' => "Die Musik-Formel: Lieder k\x{fffd}nnen zu Tr\x{fffd}nen r\x{fffd}hren und Massen in Ekstase treiben. Wie ist das m\x{fffd}glich? Forscher entschl\x{fffd}sseln, wie sich physikalische Schwingungen in Gef\x{fffd}hle verwandeln - und wie die r\x{fffd}tselhafteste aller K\x{fffd}nste einst entstanden ist. Machte erst die Musik den Menschen zum sozialen Wesen? (S.&nbsp;130)",
                         'article_link' => '/spiegel/print/d-27970590.html',
                         'has_page_no' => 0
                       },
                       {
                         'no_class' => ' class="spHeftInhaltNoPageNumber"',
                         'has_cat' => 0,
                         'title' => "\"Ich pirsche mich ans Publikum an\": Der Filmmusik-Komponist Hans Zimmer \x{fffd}ber die Erzeugung von Gef\x{fffd}hlen im Film, den Einsatz des Computers beim Komponieren und die Vertonung von Michelangelos Sch\x{fffd}pfungsfresko (S.&nbsp;142)",
                         'article_link' => '/spiegel/print/d-27970591.html',
                         'has_page_no' => 0
                       },
                       {
                         'no_class' => '',
                         'cat' => 'SONST',
                         'has_cat' => 1,
                         'title' => 'Titelbild - Musik',
                         'article_link' => '/spiegel/print/d-27970496.html',
                         'has_page_no' => 1,
                         'page' => '1'
                       },
	],
}, 'parse_result') or print Dumper($meta);



my $html = decode_utf8( File::Slurp::read_file('t/data/spiegel.de_spiegel_print_index-2003-31_2.html') );

my $meta = WWW::DerSpiegel::Scraper::index_scrape( $html );

cmp_deeply($meta, {
	'cover' => 'http://wissen.spiegel.de/wissen/titel/SP/2003/31/300/titel.jpg',
	'cover_width' => '300',
	'heft' => 'Heft 31/2003',
	'items' => [
                       {
                         'no_class' => ' class="spHeftInhaltNoPageNumber"',
                         'cat' => 'Titel',
                         'has_cat' => 1,
                         'title' => "Die Musik-Formel: Lieder k\x{fffd}nnen zu Tr\x{fffd}nen r\x{fffd}hren und Massen in Ekstase treiben. Wie ist das m\x{fffd}glich? Forscher entschl\x{fffd}sseln, wie sich physikalische Schwingungen in Gef\x{fffd}hle verwandeln - und wie die r\x{fffd}tselhafteste aller K\x{fffd}nste einst entstanden ist. Machte erst die Musik den Menschen zum sozialen Wesen? (S.&nbsp;130)",
                         'article_link' => '/spiegel/print/d-27970590.html',
                         'has_page_no' => 0
                       },
                       {
                         'no_class' => ' class="spHeftInhaltNoPageNumber"',
                         'has_cat' => 0,
                         'title' => "\"Ich pirsche mich ans Publikum an\": Der Filmmusik-Komponist Hans Zimmer \x{fffd}ber die Erzeugung von Gef\x{fffd}hlen im Film, den Einsatz des Computers beim Komponieren und die Vertonung von Michelangelos Sch\x{fffd}pfungsfresko (S.&nbsp;142)",
                         'article_link' => '/spiegel/print/d-27970591.html',
                         'has_page_no' => 0
                       },
                       {
                         'no_class' => '',
                         'cat' => 'SONST',
                         'has_cat' => 1,
                         'title' => 'Titelbild - Musik',
                         'article_link' => '/spiegel/print/d-27970496.html',
                         'has_page_no' => 1,
                         'page' => '1'
                       },
	],
}, 'parse_result') or print Dumper($meta);


my $html = decode_utf8( File::Slurp::read_file('t/data/spiegel.de_spiegel_print_d-27970498.html') );

my $meta = WWW::DerSpiegel::Scraper::article_scrape( $html );

cmp_deeply($meta, {
	pdf_link => 'http://wissen.spiegel.de/wissen/image/show.html?did=27970498&aref=image035/E0330/ROSP200303100030003.PDF&thumb=false'
}, 'parse_result') or print Dumper($meta);



