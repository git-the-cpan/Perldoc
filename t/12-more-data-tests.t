#  -*- perl -*-

use lib "t";

use TestChunks;
use YAML;

plan tests => 2*blocks();

$direction = "document";
run_is data => 'document';

$direction = "data";
run_is_deeply document => 'data';

__END__

=== Hello, world
--- data yaml_data trim
hello: world
hi: [ there, dude ]
--- document yaml_document trim
---
hello: world
hi:
  - there
  - dude

=== Basic data
--- data yaml chill xml trim
hello: world
hi:
 - there
 - dude
--- document xml thaw
<?xml version="1.0" encoding="utf-8"?>
<Hash>
  <item name='hello'>world</item>
  <item name='hi'>
    <item>there</item>
    <item>dude</item>
  </item>
</Hash>

=== Objects
--- data yaml chill xml trim
--- !perl/TestClass
  bob: bert
  bill: !perl/AnotherTestClass
    foo: bar
--- document xml thaw
<?xml version="1.0" encoding="utf-8"?>
<TestClass bob='bert'>
  <bill>
    <AnotherTestClass foo='bar'/>
  </bill>
</TestClass>

=== Objects
--- data yaml chill xml trim
--- !perl/TestClass
  bob: bert
  bill: !perl/AnotherTestClass
    fred: bob
--- document xml thaw
<?xml version="1.0" encoding="utf-8"?>
<TestClass bob='bert'>
  <bill>
    <AnotherTestClass fred='bob'/>
  </bill>
</TestClass>

=== Objects (circular ref)
--- data yaml chill xml trim
--- !perl/TestClass
  bob: bert
  bill: &1 !perl/AnotherTestClass
    fred: bob
    me: *1
--- document xml thaw
<?xml version="1.0" encoding="utf-8"?>
<TestClass bob='bert'>
  <bill>
    <AnotherTestClass fred='bob'>
      <me>
        <?error message='loop in input data structure; saw Bill twice'?>
      </me>
    </AnotherTestClass>
  </bill>
</TestClass>

