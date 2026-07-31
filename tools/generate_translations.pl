#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Encode qw(decode encode);
use FindBin qw($Bin);
use File::Path qw(make_path);
use Getopt::Long qw(GetOptions);
use JSON::PP;

my $root = "$Bin/..";
my $translate_root = "$root/Contents/mods/B42 PZLinux/42/media/lua/shared/Translate";
my $english_file = "$translate_root/EN/IG_UI_EN.txt";
my $locations_file = "$root/Contents/mods/B42 PZLinux/42/media/lua/shared/PZLinux/PZLinuxMissionLocations.lua";

my @locale_order = qw(CS DE ES HU IT JP KO NL NO PL PT PTBR RU TH TR UA CN CH);
my %targets = (
    CS => 'cs', DE => 'de', ES => 'es', HU => 'hu', IT => 'it', JP => 'ja',
    KO => 'ko', NL => 'nl', NO => 'no', PL => 'pl', PT => 'pt-PT', PTBR => 'pt-BR',
    RU => 'ru', TH => 'th', TR => 'tr', UA => 'uk', CN => 'zh-CN', CH => 'zh-TW',
);

my @requested_locales;
my $force = 0;
GetOptions('locale=s@' => \@requested_locales, 'force' => \$force) or die "Invalid arguments\n";
@requested_locales = @locale_order unless @requested_locales;
for my $locale (@requested_locales) {
    die "Unsupported locale: $locale\n" unless exists $targets{$locale};
}

sub read_utf8 {
    my ($path) = @_;
    open my $file, '<:encoding(UTF-8)', $path or die "Cannot read $path: $!\n";
    local $/;
    my $content = <$file>;
    close $file;
    return $content;
}

my @lines = split /\n/, read_utf8($english_file), -1;
pop @lines if @lines && $lines[-1] eq '';
my @entries;
for my $index (0 .. $#lines) {
    if ($lines[$index] =~ /^(\s*)(IGUI_[A-Za-z0-9_]+)\s*=\s*("(?:\\.|[^"\\])*")\s*,\s*$/) {
        my ($indent, $key, $literal) = ($1, $2, $3);
        my $value = JSON::PP->new->allow_nonref->decode($literal);
        push @entries, { line => $index, indent => $indent, key => $key, value => $value };
    }
}
die "No translation entries found in $english_file\n" unless @entries;

my %proper_names = map { $_ => 1 } ("PZLinux", "Project Zomboid", "IRC", "AOL", "Texas Hold'em", "Spiffo's");
my $location_source = read_utf8($locations_file);
while ($location_source =~ /(?:city|street|building)\s*=\s*"([^"]+)"/g) {
    $proper_names{$1} = 1 if length($1) > 1;
}
my @proper_names = sort { length($b) <=> length($a) } keys %proper_names;

sub alpha_id {
    my ($number) = @_;
    my $id = '';
    do {
        $id = chr(65 + ($number % 26)) . $id;
        $number = int($number / 26) - 1;
    } while ($number >= 0);
    return $id;
}

sub protect_text {
    my ($text) = @_;
    my %replacements;
    my $next = 0;
    $text =~ s{(%[A-Za-z]|<(?:place|container)>)}{
        my $token = '__PZVAR_' . alpha_id($next++) . '__';
        $replacements{$token} = $1;
        $token;
    }ge;
    for my $name (@proper_names) {
        next unless index($text, $name) >= 0;
        my $token = '__PZNAME_' . alpha_id($next++) . '__';
        $replacements{$token} = $name;
        $text =~ s/\Q$name\E/$token/g;
    }
    return ($text, \%replacements);
}

sub restore_text {
    my ($text, $replacements) = @_;
    for my $token (keys %$replacements) {
        my $value = $replacements->{$token};
        $text =~ s/\Q$token\E/$value/ig;
    }
    die "Unrestored translation marker in: $text\n" if $text =~ /__PZ(?:VAR|NAME)_?/i;
    $text =~ s/^\s+|\s+$//g;
    return $text;
}

sub placeholder_signature {
    my ($text) = @_;
    return join "\x1f", sort($text =~ /(%[A-Za-z]|<[^>]+>)/g);
}

sub request_translation {
    my ($text, $target) = @_;
    for my $attempt (1 .. 4) {
        open my $curl, '-|', 'curl', '-L', '-sS', '--get',
            '--data-urlencode', 'client=gtx', '--data-urlencode', 'sl=en',
            '--data-urlencode', "tl=$target", '--data-urlencode', 'dt=t',
            '--data-urlencode', "q=$text", 'https://translate.googleapis.com/translate_a/single'
            or die "Cannot start curl: $!\n";
        local $/;
        my $payload = <$curl>;
        my $success = close $curl;
        if ($success) {
            my $decoded = eval { JSON::PP->new->utf8->decode($payload) };
            if ($decoded && ref($decoded->[0]) eq 'ARRAY') {
                return join '', map { $_->[0] // '' } @{$decoded->[0]};
            }
        }
        die "Translation request failed for $target\n" if $attempt == 4;
        sleep $attempt;
    }
}

sub translate_values {
    my ($target) = @_;
    my (@protected, @replacement_maps);
    for my $entry (@entries) {
        my ($text, $replacements) = protect_text($entry->{value});
        push @protected, $text;
        push @replacement_maps, $replacements;
    }

    my @translated;
    my $start = 0;
    while ($start < @protected) {
        my ($end, $size) = ($start, 0);
        while ($end < @protected) {
            my $separator = $end > $start ? sprintf("\n__PZLSEP%04d__\n", $end) : '';
            my $addition = $separator . $protected[$end];
            last if $end > $start && $size + length($addition) > 3500;
            $size += length($addition);
            $end++;
        }

        my $batch = '';
        for my $index ($start .. $end - 1) {
            $batch .= sprintf("\n__PZLSEP%04d__\n", $index) if $index > $start;
            $batch .= $protected[$index];
        }
        my $result = request_translation($batch, $target);
        my @parts = split /\s*__PZLSEP\d{4}__\s*/, $result, -1;
        die "Translation batch split failed for $target ($start-$end)\n" unless @parts == $end - $start;
        for my $offset (0 .. $#parts) {
            my $source_index = $start + $offset;
            my $restored = restore_text($parts[$offset], $replacement_maps[$source_index]);
            my $source = $entries[$source_index]->{value};
            die "Placeholder mismatch after translating $entries[$source_index]->{key} to $target\n"
                unless placeholder_signature($source) eq placeholder_signature($restored);
            $translated[$source_index] = $restored;
        }
        print "  $target: $end/" . scalar(@protected) . "\n";
        $start = $end;
        select undef, undef, undef, 0.15;
    }
    return @translated;
}

my $json = JSON::PP->new->allow_nonref;
for my $locale (@requested_locales) {
    my $output_dir = "$translate_root/$locale";
    my $output_file = "$output_dir/IG_UI_${locale}.txt";
    die "Refusing to overwrite $output_file; use --force\n" if -e $output_file && !$force;

    print "Generating $locale ($targets{$locale})\n";
    my @translated = translate_values($targets{$locale});
    my @localized = @lines;
    $localized[0] = "IG_UI_${locale} = {";
    for my $index (0 .. $#entries) {
        my $entry = $entries[$index];
        my $literal = $json->encode($translated[$index]);
        $localized[$entry->{line}] = "$entry->{indent}$entry->{key} = $literal,";
    }

    make_path($output_dir);
    open my $output, '>:encoding(UTF-8)', $output_file or die "Cannot write $output_file: $!\n";
    print {$output} join("\n", @localized), "\n";
    close $output;
}
