
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'TraitFor-Catalyst-Controller-DBIC-DoesPaging',
  NAME      => 'TraitFor::Catalyst::Controller::DBIC::DoesPaging',
  AUTHOR    => "Arthur\ Axel\ \"fREW\"\ Schmidt\ \<frioux\+cpan\@gmail\.com\>",
  ABSTRACT  => "Helps\ you\ paginate\,\ search\,\ sort\,\ and\ more\ easily\ using\ DBIx\:\:Class",
  VERSION   => '0.092980',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
    "parent" => '0',
    "SQL::Translator" => '0',
    "FindBin" => '0',
    "Catalyst::Model::DBIC::Schema" => '0',
    "Test::More" => '0',
    "Catalyst::View::JSON" => '0',
    "Catalyst::Runtime" => '0',
    "Catalyst::Test" => '0',
    "Test::Deep" => '0',
    "DBIx::Class" => '0.08108',
  },
  test => {TESTS => 't/*.t'}
);
