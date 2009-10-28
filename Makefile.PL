
use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  DISTNAME  => 'TraitFor-Catalyst-Controller-DBIC-DoesPaging',
  NAME      => 'TraitFor::Catalyst::Controller::DBIC::DoesPaging',
  AUTHOR    => "Arthur\ Axel\ \"fREW\"\ Schmidt\ \<frioux\+cpan\@gmail\.com\>",
  ABSTRACT  => "Helps\ you\ paginate\,\ search\,\ sort\,\ and\ more\ easily\ using\ DBIx\:\:Class",
  VERSION   => '0.093010',
  EXE_FILES => [ qw() ],
  (eval { ExtUtils::MakeMaker->VERSION(6.31) } ? (LICENSE => 'perl') : ()),
  PREREQ_PM    => {
  (eval { ExtUtils::MakeMaker->VERSION(6.55_01) } ? () : (
    "SQL::Translator" => '0',
    "FindBin" => '0',
    "Catalyst::Model::DBIC::Schema" => '0',
    "Test::More" => '0.88',
    "Catalyst::View::JSON" => '0',
    "Catalyst::Test" => '0',
    "Test::Deep" => '0',
  )),
    "parent" => '0',
    "Catalyst::Runtime" => '0',
    "DBIx::Class" => '0.08108',
  },
(eval { ExtUtils::MakeMaker->VERSION(6.55_01) } ? (
  BUILD_REQUIRES    => {
    "SQL::Translator" => '0',
    "FindBin" => '0',
    "Catalyst::Model::DBIC::Schema" => '0',
    "Test::More" => '0.88',
    "Catalyst::View::JSON" => '0',
    "Catalyst::Test" => '0',
    "Test::Deep" => '0',
  },
) : ()),
  test => {TESTS => 't/*.t'}
);

