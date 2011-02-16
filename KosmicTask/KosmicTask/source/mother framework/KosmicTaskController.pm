package KosmicTaskController;

use YAML::XS;

use strict;
use warnings;
our $VERSION = "1.00";

#
# objectToString
#
sub objectToString {
	
	my $class=shift;
	
	my $object=shift;
	
	# dump object YAML string
	my $result = Dump($object);	
	
	return $result;
}

#
# printObject
#
sub printObject {
	
	my $class=shift;
	
	my $object=shift;
	
	my $result = $class->objectToString($object);	
	
	print $result;
	
}
