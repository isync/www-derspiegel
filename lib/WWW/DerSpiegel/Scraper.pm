package WWW::DerSpiegel::Scraper;

use Text::Scraper;

sub index_scrape {
	my $html = shift;

	my $obj  = Text::Scraper->new( tmpl => $index_tmpl );
	my $ref = $obj->scrape($html);
	my $meta = ${$ref}[0];

	delete($meta->{rest});

	if($meta->{items}){
		my $last_cat;
		for(@{$meta->{items}}){
			$last_cat = $_->{cat} if $_->{cat};
			$_->{cat} = $last_cat if !$_->{cat} && $last_cat;

			if(!$_->{page_no}){
				if($_->{title} =~ /nbsp;(\d+)\)$/ ){
					$_->{page_no} = $1;
					$_->{has_page_no} = 1;
					$_->{title} =~ s/ \(S\.\&nbsp;\d+\)//;
				}
			}

			delete($_->{no_class});

			die "article_link is of form ..#.." if $_->{article_link} =~ /#/;

			$_->{article_link} = 'http://www.spiegel.de'. $_->{article_link};

			($_->{document_id}) = $_->{article_link} =~ /print\/d-(\d+)\.html/;

			# we need an example link parsed out from an article page for this to complete
			# $_->{pdf_link} = 'http://wissen.spiegel.de/wissen/image/show.html?did='. $_->{document_id} .'&aref=';
			# $_->{pdf_link} = 'http://wissen.spiegel.de/wissen/image/show.html?did='. 50910408 .'&aref='. image036/2007/03/17/ROSP200701202040204.'.PDF&thumb=false',
		}
	}

	return $meta;
}

sub article_scrape {
	my $html = shift;

	my $obj  = Text::Scraper->new( tmpl => $article_tmpl );
	my $ref = $obj->scrape($html);
	my $meta = ${$ref}[0];

	($meta->{aref}) = $meta->{pdf_link} =~ /aref=([^&]+)&thumb=/;
	($meta->{pathbit}) = split(/\/ROSP/, $meta->{aref});

	return $meta;
}

our $index_tmpl = <<"INDEXTMPL";
	                        <h2 class="headline-intro"><?tmpl var heft ?></h2>
	                    </div>			

			<ul>
<?tmpl loop items ?>
                            <li>
<?tmpl if has_cat ?>
                                    <h3><?tmpl var cat ?></h3>
<?tmpl end has_cat ?>
					<dl>
<?tmpl if has_page_no ?>
	                                    <dd class="spHeftInhaltPageNumber">
	                                        <?tmpl var page_no ?>
					</dd>
<?tmpl end has_page_no ?>
	                                    <dt<?tmpl var no_class ?>>
						<a href="<?tmpl var article_link ?>"><?tmpl var title ?></a>
	                                    </dt>
									</dl>
                            	</li>
<?tmpl end items ?>
                            </ul>
<?tmpl var rest ?>
                        <div class="spArticleImageBox spAssetAlign">
                           	<img src="<?tmpl var cover ?>" width="<?tmpl var cover_width ?>" alt="Titelbild"  border="0"/>
INDEXTMPL

our $article_tmpl = '
<a class="spPdfLink" href="<?tmpl var pdf_link ?>">
                            Artikel als PDF ansehen
                        </a>
';

1;