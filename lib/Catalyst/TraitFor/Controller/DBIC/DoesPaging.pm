package Catalyst::TraitFor::Controller::DBIC::DoesPaging;
our $VERSION = '0.093010';



# ABSTRACT: Helps you paginate, search, sort, and more easily using DBIx::Class

use Moose::Role;

has ignored_params => (
   is => 'ro',
   isa => 'ArrayRef',
   default => sub { [qw{limit start sort dir _dc rm xaction}] },
);

has page_size => (
   is => 'ro',
   isa => 'Int',
   default => 25,
);

use Carp 'croak';

sub page_and_sort {
   my ($self, $c, $rs) = @_;
   $rs = $self->simple_sort($c, $rs);
   return $self->paginate($c, $rs);
}

sub paginate {
   my ($self, $c, $resultset) = @_;
   # param names should be configurable
   my $rows = $c->request->params->{limit} || $self->page_size;
   my $page =
      $c->request->params->{start}
      ? ( $c->request->params->{start} / $rows + 1 )
      : 1;

   return $resultset->search_rs( undef, {
      rows => $rows,
      page => $page
   });
}

sub search {
   my ($self, $c, $rs) = @_;
   my $q = $c->request->params;
   return $rs->controller_search($q);
}

sub sort {
   my ($self, $c, $rs) = @_;
   my $q = $c->request->params;
   return $rs->controller_sort($q);
}

sub simple_deletion {
   my ($self, $c, $rs) = @_;
   # param names should be configurable
   my $to_delete = $c->request->params->{to_delete} or croak 'Required cgi parameter (to_delete) undefined!';
   $rs->search({ id => { -in => $to_delete } })->delete();
   return $to_delete;
}

sub simple_search {
   my ($self, $c, $rs) = @_;
   my %skips  = map { $_ => 1} @{$self->ignored_params};
   my $searches = {};
   foreach ( keys %{ $c->request->params } ) {
      if ( $c->request->params->{$_} and not $skips{$_} ) {
         # should be configurable
         $searches->{$_} = { like => [map "%$_%", $c->request->param($_)] };
      }
   }

   my $rs_full = $rs->search($searches);

   return $self->page_and_sort($c, $rs_full);
}

sub simple_sort {
   my ($self, $c, $rs) = @_;
   my %order_by = ( order_by => [ $rs->result_source->primary_columns ] );
   if ( $c->request->params->{sort} ) {
      %order_by = (
         order_by => {
            q{-}.$c->request->params->{dir} => $c->request->params->{sort}
         }
      );
   }
   return $rs->search_rs(undef, { %order_by });
}

1;




=pod

=head1 NAME

Catalyst::TraitFor::Controller::DBIC::DoesPaging - Helps you paginate, search, sort, and more easily using DBIx::Class

=head1 VERSION

version 0.093010

=head1 SYNOPSIS

 package MyApp::Controller::Foo;
our $VERSION = '0.093010';


 use Moose;
 BEGIN { extends 'Catalyst::Controller' }
 with 'Catalyst::TraitFor::Controller::DBIC::DoesPaging';

 sub people {
    my ($self, $c) = @_;
    my $people = $self->page_and_sort(
       $self->simple_search(
          $self->model('DB::People');
       )
    );
    # ...
 }

=head1 DESCRIPTION

This module helps you to map various L<DBIx::Class> features to CGI parameters.
For the most part that means it will help you search, sort, and paginate with a
minimum of effort and thought.

=head1 METHODS

All methods take the context and a ResultSet as their arguments.  All methods
return a ResultSet.

=head2 page_and_sort

 my $result = $self->page_and_sort($c, $c->model('DB::Foo'));

This is a helper method that will first C<sort> your data and then C<paginate>
it.

=head2 paginate

 my $result = $self->paginate($c, $c->model('DB::Foo'));

Paginates the passed in resultset based on the following CGI parameters:

 start - first row to display
 limit - amount of rows per page

=head2 search

 my $searched_rs = $self->search($c, $c->model('DB::Foo'));

Calls the controller_search method on the passed in resultset with all of the
CGI parameters.  I like to have this look something like the following:

 # Base search dispatcher, defined in MyApp::Schema::ResultSet
 sub _build_search {
    my $self           = shift;
    my $dispatch_table = shift;
    my $q              = shift;

    my %search = ();
    my %meta   = ();

    foreach ( keys %{$q} ) {
       if ( my $fn = $dispatch_table->{$_} and $q->{$_} ) {
          my ( $tmp_search, $tmp_meta ) = $fn->( $q->{$_} );
          %search = ( %search, %{$tmp_search} );
          %meta   = ( %meta,   %{$tmp_meta} );
       }
    }

    return $self->search(\%search, \%meta);
 }

 # search method in specific resultset
 sub controller_search {
    my $self   = shift;
    my $params = shift;
    return $self->_build_search({
          status => sub {
             return { 'repair_order_status' => shift }, {};
          },
          part_id => sub {
             return {
                'lineitems.part_id' => { -like => q{%}.shift( @_ ).q{%} }
             }, { join => 'lineitems' };
          },
          serial => sub {
             return {
                'lineitems.serial' => { -like => q{%}.shift( @_ ).q{%} }
             }, { join => 'lineitems' };
          },
          id => sub {
             return { 'id' => shift }, {};
          },
          customer_id => sub {
             return { 'customer_id' => shift }, {};
          },
          repair_order_id => sub {
             return {
                'repair_order_id' => { -like => q{%}.shift( @_ ).q{%} }
             }, {};
          },
       },$params
    );
 }

=head2 sort

 my $result = $self->sort($c, $c->model('DB::Foo'));

Exactly the same as search, except calls controller_sort.  Here is how I use it:

 # Base sort dispatcher, defined in MyApp::Schema::ResultSet
 sub _build_sort {
    my $self = shift;
    my $dispatch_table = shift;
    my $default = shift;
    my $q = shift;

    my %search = ();
    my %meta   = ();

    my $direction = $q->{dir};
    my $sort      = $q->{sort};

    if ( my $fn = $dispatch_table->{$sort} ) {
       my ( $tmp_search, $tmp_meta ) = $fn->( $direction );
       %search = ( %search, %{$tmp_search} );
       %meta   = ( %meta,   %{$tmp_meta} );
    } elsif ( $sort && $direction ) {
       my ( $tmp_search, $tmp_meta ) = $default->( $sort, $direction );
       %search = ( %search, %{$tmp_search} );
       %meta   = ( %meta,   %{$tmp_meta} );
    }

    return $self->search(\%search, \%meta);
 }

 # sort method in specific resultset
 sub controller_sort {
    my $self = shift;
    my $params = shift;
    return $self->_build_sort({
         first_name => sub {
            my $direction = shift;
            return {}, {
               order_by => { "-$direction" => [qw{last_name first_name}] },
            };
         },
       }, sub {
      my $param = shift;
      my $direction = shift;
      return {}, {
         order_by => { "-$direction" => $param },
      };
       },$params
    );
 }

=head2 simple_deletion

 $self->simple_deletion($c, $c->model('DB::Foo'));

Deletes from the passed in resultset based on the following CGI parameter:

 to_delete - values of the ids of items to delete

This is the only method that does not return a ResultSet.  Instead it returns an
arrayref of the id's that it deleted.

Note that this method uses the $rs->delete method, as opposed to $rs->delete_all

=head2 simple_search

 my $searched_rs = $self->simple_search($c, $c->model('DB::Foo'));

Searches rs based on all fields in the request, except for fields listed in
C<ignored_params>.  Searches with fieldname => { -like => "%$value%" }. If there are
multiple values for a CGI parameter it will use all values via an C<or>.

=head2 simple_sort

 my $sorted_rs = $self->simple_sort($c, $c->model('DB::Foo'));

Sorts the passed in resultset based on the following CGI parameters:

 sort - field to sort by, defaults to primarky key
 dir  - direction to sort

=head1 CONFIG VARIABLES

=over 4

=item page_size

Default size of a page.  Defaults to 25.

=item ignored_params

ArrayRef of params that will be ignored in simple_search, defaults to:

 [qw{limit start sort dir _dc rm xaction}]

=back

=head1 CREDITS

Thanks to Micro Technology Services, Inc. for funding the initial development
of this module.

=head1 AUTHOR

  Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
