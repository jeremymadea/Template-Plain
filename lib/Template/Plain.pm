package Template::Plain;

use 5.006000;
use strict;
use warnings;

our $VERSION = '1.00';

# XXXXX

my $default; # Holds the default template object when class methods are used.

sub new {
  my $class = shift;
  my $content = shift || _PT_default_content();
  my $self = {
    '_delims'  => [qw/ <% %> /],
    '_content' => $content,
    '_listsep' => "\n",
  };
  bless $self, $class;
}

sub list_separator {
  my $self = shift;
  if (! ref $self) { $self = $default = $default || __PACKAGE__->new() }
  return @_ ? $self->{_listsep} = shift : $self->{_listsep};
}

sub delimiters {
  my $self = shift;
  if (! ref $self) { $self = $default = $default || __PACKAGE__->new() }
  $self->{_delims} = shift if @_ == 1;
  $self->{_delims} = [shift, shift] if @_ == 2;
  return $self->{_delims};
}

sub tags {
  my $self    = shift;
  if (! ref $self) { $self = $default = $default || __PACKAGE__->new() }
  my ($L, $R) = @{$self->{_delims}};
  my @list    = $self->{_content} =~ m/\Q$L\E\s*(.*?)\s*\Q$R\E/gm;
  return @list;
}

sub fill {
  my $self    = shift;
  if (! ref $self) { $self = $default = $default || __PACKAGE__->new() }
  my $args    = shift;
  my $replace = shift;
  my ($L, $R) = @{$self->{_delims}};
  my $text    = $self->{_content};
  $text =~ s/\Q$L\E\s*(.*?)\s*\Q$R\E/$self->_expand($1,$args)/egm;
  $self->{_content} = $text if $replace;
  return \$text;
}


# Private Methods

sub _expand {
  my $self = shift;
  my ($key, $hashr) = @_;
  my $value = $hashr->{$key};

  return '' unless defined $value;

  for (ref $value) {
    /CODE/   and do { return $value->() };
    /ARRAY/  and do { return join $self->{_listsep}, @$value };
    /SCALAR/ and do { return $$value };
    /^$/     and do { return $value };
  }
}



# Private class methods

sub _PT_default_content {

  my $FH;
  my $pkg = caller;

  no strict 'refs';

  # if DATA exists in the calling package use that.
  if ( exists ${ $pkg . '::' }{DATA} and defined *{${$pkg . '::'}{DATA}}{IO}) {
    $FH = *{${$pkg . '::'}{DATA}}{IO};

  # else if DATA exists in main, use that.
  } elsif ( exists $main::{DATA} and defined *main::DATA{IO} ){
    $FH = *main::DATA{IO};

  # else use <>
  } else {
    $FH = \*ARGV;
  }

  do { undef $/; <$FH> };

}

################################################################################
1;

__END__

=head1 NAME

Template::Plain - A Perl extension for very simple templates.

=head1 SYNOPSIS

  use Template::Plain;

  my $template = Template::Plain->new("Hello, <%World%>!\n");
  my $ref = $template->fill({ World => 'Perl People' });
  print $$ref
  exit(0);

  # Also try the bells, whistles, and variations! Like...

  # Filling placeholders with other thingies!
  my $textref = $template->fill( { Foo => \$scalar_ref,
                                   Bar => \@or_a_list,
                                   Baz => \&a_sub_ref, } );

  # Default Content!
  my $template = Template::Plain->new();

  # Default Content via a class method!
  Template::Plain->fill({ PlaceHolder => 'Your Favorite Value' });

  # Change your delimiters!
  $template->delimiters('[:', ':]');

  # Change your list separator!
  $template->list_separator(':');

  # Find the tag names in your Content!
  my @tags = $template->tags();


=head1 DESCRIPTION

This module allows for filling in placeholders in templates. It is meant to
exceedingly simple. It does not make it possible for you to actually put code
in your templates. If that is what you want, there are many other (less simple)
modules that would be a better choice.

Template::Plain works in two (intermixable) modes. When the provided methods are
called as class methods, they operate on a default template object stored in a
private class variable. This default template is created the first time any of
the methods are called as class methods. It is created by calling the
constructor without any arguments.

I've found this module to be extremely useful. I use it for all manner of things. 
Template::Plain is simple but your use of it doesn't have to be. Template::Plain can 
do a lot, especially if you make heavy use of the delimiters() method and the optional
argument to fill().

=head1 METHODS

=head2 new

The constructor can be called with either a single scalar argument or none at
all. 

When it is called with an argument, the argument is taken to be the
template content. 

When it is called without an argument, the template content is read from a 
filehandle. Which filehandle it is read from is determined as follows: If the 
DATA filehandle is found in the calling package, the template content is read 
from that. Else if the DATA filehandle is found in main::, the template content 
is read from there.  Otherwise, the template content is read from the ARGV 
filehandle.

=head2 fill

This method expects a single hashref as an argument. 

The keys of the hash referred to by the hashref should coincide with the 
placeholder names and the values should be the data to be substituted (or 
references to the data.) 

If a value is found to be a reference, it will be called if it is a code 
reference, dereferenced and joined with the defined list separator if it is a 
reference to an array, or dereferenced if it is a reference to a scalar. 

Note that a reference to a hash isn't handled specially at all. 

An optional argument can be supplied. If it is a true value, the template 
object's content will be replaced with the result of filling in its 
placeholders. This can be useful for recursively filling templates.

This method returns a reference to a scalar holding the text resulting from 
filling the template. 

=head2 delimiters

This method takes 0, 1, or 2 arguments. 

When called with at least one argument, it sets the delimiters used to define 
placeholders in the template. 

If there is exactly one argument, it is assumed to be a reference to
an array containing the left and right delimiters in that order. When called
with two arguments, they are assumed to be the left and right delimiters in
that order.  

When called with no arguments no attempt is made to set the delimiters. Instead, 
this method returns a reference to an array containing the left and
right delimiters in that order. 

The default delimiters are '<%' and '%>'.


=head2 list_separator

This method takes either zero arguments or exactly one scalar argument.

If it is called with an argument, the list separator value is set to that
value.  The list separator is a string which is used to separate the values 
when a placeholder is filled with an array.

This method always returns the current list separator. 

By default, the list separator is a newline ("\n"). 

=head2 tags

This method takes no arguments. It returns a list of the placeholder names
used in the template.

=head1 IMPORTANT NOTE

Placeholder names must not have leading/trailing whitespace. Whitespace should 
be avoided in delimiters too.

=head1 LIMITATIONS

Template::Plain reads the whole template into memory. This helps to keep Template::Plain simple.

=head1 AUTHOR

Jeremy Madea, E<lt>jeremy@cpan.orgE<gt>

=head1 BUGS

Please report any bugs or feature requests to:

C<bug-template-plain at rt.cpan.org> 

Or through the web interface at:

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-Plain>.  

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::Plain


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-Plain>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-Plain>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-Plain>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-Plain/>

=back


=head1 VERSION

Template::Simple version 1.00, released May, 2012

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Jeremy Madea

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

=head1 SEE ALSO

L<perl>.

=cut






