package Rex::Misc::Sparrow;

use strict;
use warnings;

use Rex -base => [qw(1.4 exec_autodie)];
use Rex::CMDB;

use Rex::Lang::Perl::Cpanm;

use File::Spec;
use Try::Tiny;
use YAML;

our $sparrow = get cmdb 'sparrow';

unless ( defined $sparrow ) {
  my $yaml;
  try {
    $yaml =
      YAML::LoadFile( Rex::Helper::Path::get_file_path('files/sparrow.yml') );
  }
  catch { die 'No sparrow configuration found. Aborting.' };
  $sparrow = $yaml->{sparrow};
}

our $sparrow_temp = File::Spec->tmpdir();

=pod

=head1 NAME

Rex::Misc::Sparrow - manage and run sparrow plugins

=head1 DESCRIPTION

Setup sparrow and its plugins described in the configuration file, and run them.

=head1 USAGE

Create configuration either as C<files/sparrow.yml> or in CMDB. See C<files/sparrow.yml.example> for examples.

 $ rexify --use=Rex::Misc::Sparrow
 $ rex Misc:Sparrow:setup

Example configuration.

 $ cat sparrow.yml

  sparrow:
    plugins:
      - df-check
      - nginx-check
      - perlbrew
  
=head1 TASKS

=over 4

=item setup

Installs sparrow plugin via cpanm.

=cut

desc 'Setup sparrow';
task 'setup', sub {
  cpanm -install;
  cpanm -install => [qw(Digest::MD5 Test::More Sparrow~0.1.3)];
};

=item configure

Installs sparrow plugins as described in either CMDB or in C<files/sparrow.yml>.

=cut

desc 'Configure sparrow plugins';
task 'configure', sub {
  run 'sparrow index update';
  foreach my $plg ( @{ $sparrow->{plugins} } ) {
    run "sparrow plg install $plg";
  }
};

=item plugin_run

Runs sparrow plugin(s) (with parameters).

 $ rex -qw Misc:Sparrow:plugin_run # run all plugins
 $ rex -qw Misc:Sparrow:plugin_run --plugin=df-check  # run df-check plugin only
 $ rex -qw Misc:Sparrow:plugin_run --plugin=df-check --threshold=88 # run df-check plugin with parameter

=cut

desc 'Runs sparrow plugins';
task 'plugin_run', sub {
  my $params = shift;
  foreach my $plg (
    grep {
      my $name = $_;
      $params->{plugin}
        ? ( $name eq $params->{plugin} )
        : 1
    } @{ $sparrow->{plugins} }
    )
  {
    my $plg_params = $params || {};
    delete @{$plg_params}{qw{plugin Misc:Sparrow:plugin_run}};
    my $plg_params_string = '';
    for my $n ( keys %{$plg_params} ) {
      if ( $plg_params->{$n} =~ /\s/ ) {
        $plg_params_string .= " --param $n=\"'" . ( $plg_params->{$n} ) . "'\"";
      }
      else {
        $plg_params_string .= " --param $n=" . ( $plg_params->{$n} );
      }
    }
    say scalar run "sparrow plg run $plg $plg_params_string";
  }
};

=back

=head1 See also

https://sparrowhub.org

=cut 

1;
