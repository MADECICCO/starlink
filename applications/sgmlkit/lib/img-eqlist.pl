#! /usr/bin/perl -w

$RCSID = '$Id$';

#+
#  <routinename id=img-eqlist>
#    img-eqlist.pl
#
#  <purpose>
#    Process a file of LaTeX fragments.
#
#  <description>
#    <p>Format of the input is
#    <verbatim>
#     ...LaTeX maths code
#     %%imgmath type1 label1
#     ...LaTeX maths code...
#     %%imgmath type2 label2
#     ...
#     %%startmdefs
#     ...
#     %%endmdefs
#    </verbatim>
#    <p>The `labeln' field may be any identifying string generated by whatever
#    generated this file.  The `typen' field must be one of
#    <code>inline</>, <code>equation</>, or <code>eqnarray</> (the
#    first corresponds to inline maths mode in LaTeX, and the other
#    two to the correspondingly named LaTeX environments).  Lines between
#    <code>%%startmdefs</> and <code>%%endmdefs</> are copied verbatim
#    to the output.
#
#    <p>We spit out two files, based on the filename root of the argument.
#    The text one consists of a sequence of lines starting with the
#    format `label &lt;labelname> &lt;filename>', which maps equation labels
#    (the second parameter of the <code>%%imgmath</> lines above to
#    filenames generated by this script.  The 
#    LaTeX file consists of a LaTeX document with one equation per page.  The
#    latter should be processed by LaTeX plus whatever dvi to bitmap magic
#    you need, making sure that the resulting image filenames match those
#    in the labels file.
#
#    <p>This script is designed to work with <code>dvi2bitmap</>, as
#    it uses dvi2bitmap specials to control the output filenames.  See
#    the <code>dvi2bitmap</> documentation for details.
#
#  <argumentlist>
#    <parameter>infile
#    <type>filename
#    <description>File containing LaTeX maths fragments, of the format
#    described above.
#
#  <diytopic>Options
#     <dl>
#     <dt>--imgformat (gif|png)
#       <dd>specifies the format of the images to be
#       generated.  Must be an image type recognised by dvi2bitmap.
#     <dt>--version
#       <dd>display the current version number and exit.
#     </dl>
#
#  <authorlist>
#  <author id=ng affiliation='Starlink, University of Glasgow'>Norman Gray
#-

$ident_string = "Starlink SGML system, release ((PKG_VERS))";

# Defaults
$imgformat = 'png';
$eqcount = '001';

while ($#ARGV >= 0) {
    if ($ARGV[0] eq '--imgformat') {
	shift;
	$#ARGV >= 0 || Usage ();
	$imgformat = $ARGV[0];
    } elsif ($ARGV[0] eq '--version') {
	print "$ident_string\n$RCSID\n";
	exit (0);
    } elsif ($ARGV[0] =~ /^-/) {
	Usage ();
    } elsif (defined ($infile)) {
	Usage ();
	last;
    } else {
	$infile = $ARGV[0];
    }
    shift;
}

defined ($infile) || Usage();

($filenameroot = $infile) =~ s/\..*$//;

%eqtypes = ( 'start-inline' => '$',
	     'end-inline' => '$\special{dvi2bitmap crop all 0}\DBstrut',
	     'start-equation' => '\begin{equation}',
	     'end-equation' => '\end{equation}',
	     'start-eqnarray' => '\begin{eqnarray}',
	     'end-eqnarray' => '\end{eqnarray}',
	     );

open (EQIN, "$infile")
    || die "Can't open $infile to read";
#open (SGMLOUT, ">$filenameroot.imgeq.sgml")
#    || die "Can't open $filenameroot.imgeq-sgml to write";
open (LABELOUT, ">$filenameroot.imgeq.labelmap")
    || die "Can't open $filenameroot.imgeq.labelmap to write";
open (LATEXOUT, ">$filenameroot.imgeq.tex")
    || die "Can't open $filenameroot.imgeq.tex to write";


LaTeXHeader (\*LATEXOUT);
print LATEXOUT "\\special{dvi2bitmap default imageformat $imgformat}\n";

#print SGMLOUT "<!DOCTYPE img-eqlist SYSTEM 'img-eqlist'>\n<img-eqlist>\n";

$eqn = '';
while (defined($line = <EQIN>)) {
    if ($line =~ /^%%imgmath/) {
	chop($line);
	($dummy,$eqtype,$label) = split (/ /, $line);
	$outfilename = "$filenameroot.imgeq$eqcount.$imgformat";
	# Calculate checksum.  Base the checksum on the equation type
	# as well as its contents.
	($checkeqn = $eqtype.$eqn) =~ s/\s+//sg;
	$checksum = simple_checksum($checkeqn);
	if (defined($checklist{$checksum})) {
	    # already seen this equation
	    #print SGMLOUT "<img-eq label='$label' sysid='" .
		#$checklist{$checksum} . "'>\n";
	    print LABELOUT "label $label " .
		$checklist{$checksum} . "\n";
	} else {
	    $eqn =~ s/\s+$//s;
	    print LATEXOUT $eqtypes{'start-'.$eqtype} .
		$eqn . 
		$eqtypes{'end-'.$eqtype} .
		"\n\\special{dvi2bitmap outputfile $outfilename}\n\\newpage\n";
	    #print SGMLOUT "<img-eq label='$label' sysid='$outfilename'>\n";
	    print LABELOUT "label $label $outfilename\n";
	    $checklist{$checksum} = $outfilename;
	    $eqcount++;
	}
	$eqn = '';
    } elsif ($line =~ /^%%startmdefs/) {
	print LATEXOUT "%%% mdefs...\n";
	while (defined($line = <EQIN>)) {
	    if ($line =~ /^%%endmdefs/) {
		last;
	    } else {
		print LATEXOUT $line;
	    }
	}
	print LATEXOUT "%%% ...mdefs\n";
    } elsif ($line =~ /^%%eqno/) {
	chop ($line);
	($dummy,$eqno) = split (/ /, $line);
	$eqn .= "\\SetEqnNum{$eqno}";
    } else {
	$eqn .= $line unless ($line =~ /^\s*$/);
    }
}
print LATEXOUT "\\end{document}\n";
#print SGMLOUT "</img-eqlist>\n";

#close (SGMLOUT);
close (LABELOUT);
close (LATEXOUT);
close (EQIN);

exit 0;

sub LaTeXHeader {
    my $fh = shift;
    print $fh <<'EOT';
\documentclass[fleqn]{article}
\pagestyle{empty}
\oddsidemargin=10pt
\hoffset=0pt
\mathindent=2cm
\makeatletter
\newif\if@SetEqnNum\@SetEqnNumfalse
\def\SetEqnNum#1{\global\def\Eqn@Number{#1}\global\@SetEqnNumtrue}
%\def\@eqnnum{{\normalfont \normalcolor (\Eqn@Number)}}
% leqno:
\def\@eqnnum{\if@SetEqnNum 
    \hb@xt@.01\p@{}%
    \rlap{\normalfont\normalcolor
      \hskip -\displaywidth(\Eqn@Number)}
    \global\@SetEqnNumfalse
  \else
    \relax
  \fi}
%\def\equation{$$}
%\def\endequation{\if@SetEqnNum\eqno \hbox{\@eqnnum}\global\@SetEqnNumfalse\fi 
%    $$\@ignoretrue}
\def\@@eqncr{\let\reserved@a\relax
    \ifcase\@eqcnt \def\reserved@a{& & &}\or \def\reserved@a{& &}%
     \or \def\reserved@a{&}\else
       \let\reserved@a\@empty
       \@latex@error{Too many columns in eqnarray environment}\@ehc\fi
     \reserved@a \if@SetEqnNum\@eqnnum\global\@SetEqnNumfalse\fi
     \global\@eqcnt\z@\cr}
% Put a dvi2bitmap strut into the output, of the same size as a \strut
{\catcode`p=12 \catcode`t=12 \gdef\DB@PT#1pt{#1}}
\def\DBstrut{\strut\special{dvi2bitmap strut 0 0 \expandafter\DB@PT\the\ht\strutbox\space\expandafter\DB@PT\the\dp\strutbox}}
\makeatother
\begin{document}
\special{dvi2bitmap default crop all 10 absolute crop left 0}
EOT
}

sub Usage {
    die "$ident_string\nUsage: $0 [--imgformat fmt] [--version] filename\n";
}

# Provide a simple checksum with a decent hash length.
#
# Repeatedly call crypt_checksum, concatenating the results.  This is a
# respectable way to increase the hash size of an algorithm (see Schneier,
# for example).
#
# This checksum isn't cryptographically secure, but it's good enough to 
# allow us to more-or-less guarantee that if two strings give the same
# hash, they're the same string.
#
# We can make an arbitrarily long hash here, but a single round gives us 
# 2^(56) values, which should be enough, without being overly slow.
#
# Do _not_ use unpack("%32C*",...) as a checksum - it doesn't seem to 
# fill the 32 bits the documentation semi-claims it does. 
#
sub simple_checksum {
    my $msg = shift;
    my $cs = "";
    my $cs16;
    my $lcount;
#    for ($lcount=0; $lcount<2; $lcount++)
#    {
	$cs_short = crypt_checksum ($cs.$msg);
	$cs = $cs_short.$cs;
	# I _think this is robust, since crypt()ing the result of crypt() 
	# should be safe.
#    }
    return $cs;
}

# Use the crypt() function to obtain a checksum.  Call it repeatedly, taking
# the message in blocks of 4 characters, using the result of the previous
# round as half of the `password'.  Returns a string 11 characters long.
sub crypt_checksum {
    my $msg = shift;
    my $msglen = length($msg);
    my $i;
    my $salt = "xx";
    for ($i=0; $i<$msglen; $i+=4)
    {
	$cs = crypt (substr($salt,0,4).substr($msg, $i, 4), $salt);
	$salt = substr($cs,2);
    }
    return $salt;
}
