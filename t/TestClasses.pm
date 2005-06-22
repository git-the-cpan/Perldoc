
package TestObject;
use base qw(Class::Tangram);
our $fields = { string => ["banana"],
		ref => ["apple"],
		array => ["pear"],
		hash => ["orange"],
	      };

package myMessageClass;
use base qw(Class::Tangram);
our $fields = { array => ["banana"],
		string => ["test"],
	      };

1;
