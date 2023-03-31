use strict;
use warnings;

use Text::Markdown 'markdown';
use Data::Dumper;

sub get_template {
	my %map = ("begin" => "", "end" => "");
	my $str;
	
	open(my $file, "<", "template.html") or die "unable to open template.html: $!";

	while ($str = <$file>) {
		if ($str =~ /\{\{POST HERE\}\}/) {
			last;
		} else {
			$map{'begin'} .= $str;
		}
	}

	while ($str = <$file>) {
		$map{'end'} .= $str;
	}
	
	return \%map;
}

sub read_post {
	my %map;
	my $str;

	open(my $file, "<", shift(@_)) or die "ur mom gay: $!";

	$str = <$file>;

	unless ($str =~ /^\[settings\]$/) {
		print STDERR "u need [settings] at the top of the file bro\n";
		die "no [settings]";
	}
	
	while ($str = <$file>) {
		if ($str =~ /^([a-zA-Z0-9]+)\s+\=\s+(.*)$/) {
			$map{$1} = $2;
		} elsif ($str =~ /^\[settings\]$/) {
			last;
		} else {
			die "wtf did u do bro";
		}
	}

	while ($str = <$file>) {
		push @{$map{"content"}}, $str;
	}
	
	close($file);

	return \%map;
}

sub write_post {
	my %map = %{shift(@_)};
	my $out = shift(@_);

	my %template = %{get_template()};

	open(my $file, ">", $out) or die "unable to open $out: $!";
	
	printf $file ($template{'begin'}, $map{'title'});
	
	my $line;
	while ($line = shift(@{$map{'content'}})) {
		if ($line =~ /^`{3}/) {
			if ($line =~ /^`{3}(.*)$/) {
				printf $file ('<pre><code class="language-%s">', $1);
			} else {
				print $file '<pre><code class="language-plaintext">';
			}
			
			$line = shift(@{$map{'content'}});
			until ($line =~ /^`{3}$/) {
				print $file $line;
				$line = shift(@{$map{'content'}});
			}
			print $file "</code></pre>\n";
		} elsif ($line =~ /^\s*$/) {
			print $file '<div class="space"></div>';
		} else {
			print $file markdown($line);
		}
	}
	
	print $file $template{'end'};
	
	close($file);
}

sub write_index {
	my %map = %{shift(@_)};
	my %template = %{get_template()};
	my %settings;
	my $str;

	open(my $ind, "<", "index.md") or die "ur mom gay: $!";

	$str = <$ind>;

	unless ($str =~ /^\[settings\]$/) {
		print STDERR "u need [settings] at the top of the file bro\n";
		die "no [settings]";
	}
	
	while ($str = <$ind>) {
		if ($str =~ /^([a-zA-Z0-9]+)\s+\=\s+(.*)$/) {
			$settings{$1} = $2;
		} elsif ($str =~ /^\[settings\]$/) {
			last;
		} else {
			die "wtf did u do bro";
		}
	}

	open(my $file, ">", "index.html") or die "unable to open index.html: $!";

	printf $file ($template{'begin'}, $settings{'title'});

	while ($str = <$ind>) {
		print $file '<p class="bio">', $str, '</p>';
	}

	print $file ('<h1 align="center">Blog Posts</h1>');

	foreach my $key (keys %map) {
		my @values = @{$map{$key}};
		printf $file ('<a class="title" href="/static/%s">%s</a><p class="description">%s</p>', $key, $values[0], $values[1]);
	}

	print $file $template{'end'};
}

opendir(my $dir, "./posts") or die "unable to open dir: %!";
my @files = readdir $dir;
closedir($dir);

my %data;

foreach (@files) {
	if ($_ =~ /md$/) {
		my $in = "./posts/" . $_;
		my %map = %{read_post $in};
		$_ =~ s/\.md$/\.html/;
		my $out = "./static/" . $_;
		
		$data{$_} = [ $map{'title'}, $map{'description'} ];

		
		write_post(\%map, $out);
	}
}

write_index \%data;
