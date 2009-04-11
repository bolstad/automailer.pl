#!/usr/bin/env perl

use MIME::QuotedPrint;
use MIME::Base64;
use Mail::Sendmail 0.75;
use Getopt::Long;

use strict;

# == settings

my $boundary = "Automailer.pl_" . int( rand(1000) );

my $sender       = 'kers@atdt.nu';
my $recipient    = 'kers@atdt.nu';
my $mail_subject = 'Test attachment';
my $smtp_server  = 'localhost';
my $message      = "Voilà le fichier demandé";
my $file;
my $charset = 'utf-8';
my $help;
my $filename;
my $debug;
my %mail;

sub usage {
    print "Unknown option: @_\n" if (@_);
    print "usage: program --file /path/to/attachment [--from from\@adress]"
      . " [--to to\@adress] [--subject 'Mail subject'] [--smtp smtp.server.tld]"
      . " [--message 'The mail body text'] [--charset charset] [--help|-?]\n";
    exit;
}

sub create_mail {

    chomp($mail_subject);
    $message = encode_qp($message);

    %mail = (
        from    => $sender,
        to      => $recipient,
        subject => $mail_subject,
        smtp    => $smtp_server
    );
    $mail{'content-type'} = "multipart/mixed; boundary=\"$boundary\"";
    use File::Basename;
    $filename = basename($file);
    open( F, $file ) or die "Cannot read $file: $!";
    binmode F;
    undef $/;
    $mail{body} = encode_base64(<F>);
    close F;

    $boundary = '--' . $boundary;
    $mail{body} = <<END_OF_BODY;
$boundary
Content-Type: text/plain; charset="$charset"
Content-Transfer-Encoding: quoted-printable

$message
$boundary
Content-Type: application/octet-stream; name="$filename"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="$filename"

$mail{body}
$boundary--
END_OF_BODY

}

main:
{
    usage()
      if (
        !GetOptions(
            "from=s"    => \$sender,
            "to=s"      => \$recipient,
            "subject=s" => \$mail_subject,
            "smtp=s"    => \$smtp_server,
            "message=s" => \$message,
            "file=s"    => \$file,
            "charset=s" => \$file,
            'help|?'    => \$help,
        )
        or !defined($file)

        # or @ARGV < 1
        or defined $help
      );
    &create_mail;

    print "From:     $sender\n";
    print "To:       $recipient\n";
    print "Subject:  $mail_subject\n";
    print "SMTP:     $smtp_server\n";
    print "\n";
    print "Mail text:\n$message\n";
    print "Filename $file (displayed as $filename)\n\n";
    sendmail(%mail) || print "Error: $Mail::Sendmail::error\n";
}
