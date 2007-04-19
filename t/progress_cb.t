#!perl

use strict;
use warnings;
use Test::More tests => 39;
use Test::Exception;
use Scalar::Util qw/looks_like_number/;

BEGIN {
	use_ok( 'Crypt::GpgME' );
}

delete $ENV{GPG_AGENT_INFO};
$ENV{GNUPGHOME} = 't/gpg';

my $ctx;
lives_ok (sub {
        $ctx = Crypt::GpgME->new;
}, 'create new context');

isa_ok ($ctx, 'Crypt::GpgME');

my $plain = Crypt::GpgME::Data->new;
$plain->write('test test test');

$ctx->set_passphrase_cb(sub { return 'abc' });

my $called = 0;

sub progress_cb {
    is (@_, 5, 'cb got 5 params');

    my ($c, $what, $type, $current, $total) = @_;

    isa_ok ($c, 'Crypt::GpgME');
    ok($c == $ctx, 'context references are equal');
    is ($what, 'stdin', 'what looks sane');
    like ($type, qr/^.$/, 'type looks sane'); #FIXME: what chars are valid?
    ok (looks_like_number($current), 'current looks sane');
    ok (looks_like_number($total), 'total looks sane');

    ++$called;
}

lives_ok (sub {
        $ctx->set_progress_cb(\&progress_cb);
}, 'setting progress cb without user data');

is ($called, 0, 'just setting the cb doesn\'t call it');

    $ctx->sign($plain, 'clear');

ok ($called > 0, 'signing calls the cb');

$called = 0;

sub progress_cb_ud {
    is (@_, 6, 'cb got 6 params');

    my ($c, $what, $type, $current, $total, $user_data) = @_;

    isa_ok ($c, 'Crypt::GpgME');
    ok($c == $ctx, 'context references are equal');
    is ($what, 'stdin', 'what looks sane');
    like ($type, qr/^.$/, 'type looks sane'); #FIXME: what chars are valid?
    ok (looks_like_number($current), 'current looks sane');
    ok (looks_like_number($total), 'total looks sane');
    is ($user_data, 'foo', 'user data looks sane');

    ++$called;
}

lives_ok (sub {
        $ctx->set_progress_cb(\&progress_cb_ud, 'foo');
}, 'setting progress cb with user data');

is ($called, 0, 'just setting the cb doesn\'t call it');

eval {
    $ctx->sign($plain, 'clear');
};

ok ($called > 0, 'signing calls the cb');
