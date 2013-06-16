#!perl
use strict;
use warnings;

use File::Temp qw{ tempfile };
use Perl::PrereqScanner;
use PPI::Document;
use Try::Tiny;

use Test::More;

sub prereq_is {
  my ($str, $want, $comment) = @_;
  $comment ||= $str;

  my $scanner = Perl::PrereqScanner->new({scanners => [qw( TestRequires )]});

  # scan_ppi_document
  try {
    my $result = $scanner->scan_ppi_document(PPI::Document->new(\$str));
    is_deeply($result->as_string_hash, $want, $comment);
  }
  catch {
    fail("scanner died on: $comment");
    diag($_);
  };

  # scan_string
  try {
    my $result = $scanner->scan_string($str);
    is_deeply($result->as_string_hash, $want, $comment);
  }
  catch {
    fail("scanner died on: $comment");
    diag($_);
  };

  # scan_file
  try {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh $str;
    close $fh;
    my $result = $scanner->scan_file($filename);
    is_deeply($result->as_string_hash, $want, $comment);
  }
  catch {
    fail("scanner died on: $comment");
    diag($_);
  };
}

prereq_is('', {}, '(empty string)');

prereq_is("use Test::Requires { 'Test::Pod' => 1.46 }", {'Test::Pod' => 0 });

prereq_is("use Test::Requires { 'Test::Extra' => 1.46 }",
  {'Test::Extra' => 0 });

prereq_is('use Test::Requires qw[MIME::Types] }', {'MIME::Types' => 0});

prereq_is(
  'use Test::Requires qw(IO::Handle::Util LWP::Protocol::http10)',
  {'IO::Handle::Util' => 0, 'LWP::Protocol::http10' => 0,}
);

prereq_is(
'use Test::Requires {
  "Test::Test1" => \'1.01\',
  \'Test::Test2\' => 2.02,
  }',
{
'Test::Test1' => 0,
'Test::Test2' => 0,
}
);


done_testing;

__END__

# we are only checking for module names so version string will always be zero