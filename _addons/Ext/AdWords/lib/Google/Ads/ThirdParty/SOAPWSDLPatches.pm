# Copyright 2011, Google Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Includes multiple patched modules from the SOAP::WSDL distribution.

no warnings qw(redefine);
no strict qw(refs);
use version;

use Scalar::Util qw(blessed);

# Loading patched packages first.
use SOAP::WSDL::Expat::Base;
use SOAP::WSDL::Expat::MessageParser;
use SOAP::WSDL::XSD::Typelib::ComplexType;

# Silencing annoying third-party library warnings.
$SIG{__WARN__}= sub {
  warn @_ unless
    $_[0] =~ /Tie::Hash::FIELDS|Cache::RemovalStrategy|XPath\/
        Node\/Element|XMLSchemaSOAP1_2::as_dateTime/;
};

package SOAP::WSDL::Expat::MessageParser;

use Carp;
use Google::Ads::Common::XPathSAXParser;

# PATCH Overriding the SAX Parser initialization to use ours.
sub parse_string {
  my $xml = $_[1];
  my $parser = $_[0]->_initialize(Google::Ads::Common::XPathSAXParser->new());
  eval {
    $parser->parse($xml);
  };
  croak($@) if $@;
  delete $_[0]->{parser};
  return $_[0]->{data};
}
# END PATCH

sub _initialize {
  my ($self, $parser) = @_;

  # Removing potential old results.
  delete $self->{data};
  delete $self->{header};
  my $characters;
  my $current = undef;

  # Setting up variables for depth-first tree traversal.
  my $list = [];
  my $path = [];
  my $skip = 0;
  my $depth = 0;

  # Executing sanity checks of main SOAP response headers.
  my %content_check = $self->{strict}?
    (
      0 => sub {
        die "Bad top node $_[1]" if $_[1] ne "Envelope";
        die "Bad namespace for SOAP envelope: " . $_[0]->recognized_string()
          if $_[0]->namespace() ne
            "http://schemas.xmlsoap.org/soap/envelope/";
        $depth++;
        return;
      },
      1 => sub {
        $depth++;
        if ($_[1] eq "Body") {
          if (exists $self->{data}) {
            $self->{header} = $self->{data};
            delete $self->{data};
            $list = [];
            $path = [];
            undef $current;
          }
        }
        return;
      }
    ):
    (
      0 => sub {
        $depth++;
      },
      1 => sub {
        $depth++;
      }
    );

  # Using "globals" for speed.
  # PATCH Added global variables to check for method package existant at
  # runtime.
  my ($_prefix, $_add_method, $_add_method_package, $_set_method,
      $_set_method_package, $_class, $_leaf) = ();
  # END OF PATCH
  my $char_handler = sub {
    # Returning if not a leaf.
    return if (!$_leaf);
    $characters .= $_[1];
    return;
  };
  $parser->set_handlers({
    Start => sub {
      # PATCH Added more input coming from the SAX parser
      my ($parser, $element, $attrs, $node) = @_;
      # END PATCH

      $_leaf = 1;

      return &{$content_check{$depth}} if exists $content_check{$depth};

      # Resolving class of this element.
      my $typemap = $self->{class_resolver}->get_typemap();
      my $name = "";

      # PATCH Checking if the xsi:type attribute is set hence generating a
      # different path to look in the typemap.
      if (not $attrs->{"type"}) {
        $name = $_[1];
      } else {
        my $attr_type = $attrs->{"type"};
        $attr_type =~ s/(.*:)?(.*)/$2/;
        $name = $_[1] . "[$attr_type]";
      }
      # END PATCH

      # Adding one more entry to the path
      push @{$path}, $name;

      # Skipping the element if is marked __SKIP__.
      return if $skip;

      $_class = $typemap->{join("/", @{$path}) };

      if (!defined($_class) and $self->{strict}) {
        die "Cannot resolve class for " . $name . " path " .
            join("/", @{$path}) . " via " . $self->{class_resolver};
      }
      if (!defined($_class) or ($_class eq "__SKIP__")) {
        $skip = join("/", @{$path});
        $_[0]->setHandlers(Char => undef);
        return;
      }

      # Stepping down, adding $current to the list element of the current
      # branch being visited.
      push @$list, $current;

      # Cleaning up current. Mainly to help profilers find the real hot spots.
      undef $current;

      $characters = q{};

      $current = pop @{$OBJECT_CACHE_REF->{$_class}};
      if (not defined $current) {
        my $o = Class::Std::Fast::ID();
        $current = bless \$o, $_class;
      }

      # PATCH Creating a double link between the SOAP Object and the parser
      # node, so it can be later use for XPath searches.
      Google::Ads::Common::XPathSAXParser::link_object_to_node($current, $node);
      # END PATCH

      # Setting attributes if there are any.
      if ($attrs && $current->can("attr")) {
        $current->attr($attrs);
      }
      $depth++;
      return;
    },
    Char => $char_handler,
    End => sub {
      # End of the element stepping up in the current branch path.
      pop @{$path};

      # Checking if element need to be skipped __SKIP__.
      if ($skip) {
        return if $skip ne join "/", @{$path}, $_[1];
        $skip = 0;
        $_[0]->setHandlers(Char => $char_handler);
        return;
      }
      $depth--;

      # Setting character values only if a leaf.
      if ($_leaf) {
        $SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType::___value
            ->{$$current} = $characters
            if defined $characters && defined $current;
      }

      $characters = q{};
      $_leaf = 0;

      # Finishing if at the top of the tree of elements, no more parents.
      if (not defined $list->[-1]) {
        $self->{data} = $current if (not exists $self->{data});
        return;
      }

      # Method to be called in the parent to add the current object to it.
      $_add_method = "add_$_[1]";

      # Fixing up XML names for Perl names.
      $_add_method =~ s{\.}{__}xg;
      $_add_method =~ s{\-}{_}xg;

      # PATCH Adding the element if the method to add is defined in the
      # parent.
      eval('use ' . ref($list->[-1]));
      eval {
        $list->[-1]->$_add_method($current);
      };
      if ($@) {
        warn ("Couldn't find a setter $_add_method for object of type " .
              ref($current) . " in object of type " . ref($list->[-1]) .
              " method " . $_add_method);
      }
      # END PATCH

      #Stepping up in the current object hierarchy.
      $current = pop @$list;
      return;
    }
  });
  return $parser;
}

package SOAP::WSDL::XSD::Typelib::ComplexType;

# Patching of the WSDL library to include xsi:type attribute for
# elements that inherit other complex elements like ManualCPC.
sub serialize_attr {
  my ($self, $args) = @_;
  my $result = q{};
  if ($SOAP::WSDL::XSD::Typelib::ComplexType::xml_attr_of{${$_[0]}}) {
    $result =
      $SOAP::WSDL::XSD::Typelib::ComplexType::xml_attr_of{${$_[0]}}
          ->serialize();
  }

  # PATCH to include xsi:type when necessary.
  if ($args->{xsitype}) {
    $result = $result . " xsi:type=\"$args->{xsitype}\" ";
  }
  # END OF PATCH

  if ($args->{xsitypens}) {
    $result = $result . " xmlns:$args->{xsitypens}->{name}=\"" .
        "$args->{xsitypens}->{value}\" ";
  }

  return $result;
}


# Redefining complex type factory method to allow subclasses to be passed to
# attribute setters, so for example a
# set_operations(\@{ARRAY_OF_SUBCLASSES_OF_OPERATION}) can be performed.
sub _factory {
  my $class = shift;
  # PATCH Access via typeglobs so we can reference and change attributes and
  # names from the real ComplexType package.
  my $ATTRIBUTES_OF = *SOAP::WSDL::XSD::Typelib::ComplexType::ATTRIBUTES_OF;
  my $NAMES_OF = *SOAP::WSDL::XSD::Typelib::ComplexType::NAMES_OF;
  my $CLASSES_OF = *SOAP::WSDL::XSD::Typelib::ComplexType::CLASSES_OF;
  my $ELEMENTS_FROM = *SOAP::WSDL::XSD::Typelib::ComplexType::ELEMENTS_FROM;
  my $ELEMENT_FORM_QUALIFIED_OF =
      *SOAP::WSDL::XSD::Typelib::ComplexType::ELEMENT_FORM_QUALIFIED_OF;
  # END PATCH
  $ELEMENTS_FROM->{$class} = shift;
  $ATTRIBUTES_OF->{$class} = shift;
  $CLASSES_OF->{$class} = shift;
  $NAMES_OF->{$class} = shift;

  while (my ($name, $attribute_ref) = each %{$ATTRIBUTES_OF->{$class}}) {
    my $type = $CLASSES_OF->{$class}->{$name} or
        croak "No class given for $name";
    $type->isa('UNIVERSAL') or eval "require $type" or croak $@;
    my $is_list = $type->isa('SOAP::WSDL::XSD::Typelib::Builtin::list');
    my $method_name = $name;
    $method_name =~s{[\.\-]}{_}xmsg;
    *{"$class\::set_$method_name"} = sub {
      if (not $#_) {
        delete $attribute_ref->{${$_[0]}};
        return;
      };
      my $is_ref = ref $_[1];
      $attribute_ref->{${$_[0]}} = ($is_ref)?
          ($is_ref eq 'ARRAY')?
              $is_list?
                  $type->new({value => $_[1]}):
                  [map {
                         ref $_?
                             ref $_ eq 'HASH'?
                                 # PATCH Call custom hash to object subroutine
                                 # that correctly handles xsi_type.
                                 SOAP::WSDL::XSD::Typelib::ComplexType::_hash_to_object($type, $_):
                                 # An isa type comparison is needed to check
                                 # for the right type.
                                 $_->isa($type)?
                                 # END OF PATCH
                                     $_ : croak "cannot use " . ref($_) .
                                              " reference as value for" .
                                              " $name - $type required"
                             : $type->new({value => $_})
                       } @{$_[1]}]:
              $is_ref eq 'HASH'?
                  # PATCH Call custom hash to object subroutine that correctly
                  # handles xsi_type.
                  do {
                    SOAP::WSDL::XSD::Typelib::ComplexType::_hash_to_object(
                        $type, $_[1]);
                  }:
                  # END OF PATCH
                  blessed $_[1] && $_[1]->isa($type)?
                      $_[1]:
                      die croak "cannot use $is_ref reference as value for " .
                                "$name - $type required":
          defined $_[1]?$type->new({value => $_[1]}):();
      return;
    };

    *{"$class\::add_$method_name"} = sub {
      warn "attempting to add empty value to " . ref $_[0]
          if not defined $_[1];

      if (not exists $attribute_ref->{${$_[0]}}) {
        $attribute_ref->{${$_[0]}} = $_[1];
        return;
      }

      if (not ref $attribute_ref->{${$_[0]}} eq 'ARRAY') {
        $attribute_ref->{${$_[0]}} = [$attribute_ref->{${$_[0]}}, $_[1]];
        return;
      }

      push @{$attribute_ref->{${$_[0]}}}, $_[1];
      return;
    };
  }

  *{"$class\::new"} = sub {
    my $self = bless \(my $o = Class::Std::Fast::ID()), $_[0];

    if (exists $_[1]->{xmlattr}) {
      $self->attr(delete $_[1]->{xmlattr});
    }

    # Iterate over keys of arguments and call set appropriate field in class
    map {($ATTRIBUTES_OF->{$class}->{$_})?
        do {
          my $method = "set_$_";
          $method =~s{[\.\-]}{_}xmsg;
          eval {
            $self->$method($_[1]->{$_});
          };
        }:
        # PATCH Ignoring xsi_type as a regular attribute of a given HASH since
        # is treated specially later.
        $_ =~ m{ \A
                  xmlns|xsi_type
               }xms?():
              do {
                croak "unknown field $_ in $class. Valid fields are:\n" .
                      join(', ', @{$ELEMENTS_FROM->{$class}}) . "\n" .
                      "Structure given:\n" . Dumper (@_)
              };
        # END PATCH
    } keys %{$_[1]};
    return $self;
  };

  *{"$class\::_serialize"} = sub {
    my $ident = ${$_[0]};
    my $option_ref = $_[1];

    return \join q{} , map {
      my $element = $ATTRIBUTES_OF->{$class}->{$_}->{$ident};

      if (defined $element) {
        $element = [$element] if not ref $element eq 'ARRAY';
        my $name = $NAMES_OF->{$class}->{$_} || $_;
        my $target_namespace = $_[0]->get_xmlns();
        map {
          if ($_->isa('SOAP::WSDL::XSD::Typelib::Element')) {
            ($target_namespace ne $_->get_xmlns())?
                $_->serialize({name => $name, qualified => 1}):
                $_->serialize({name => $name});
          } else {
            if (!defined $ELEMENT_FORM_QUALIFIED_OF->{$class} or
                $ELEMENT_FORM_QUALIFIED_OF->{$class}) {
              if (exists $option_ref->{xmlns_stack} &&
                  (scalar @{$option_ref->{xmlns_stack}} >= 2) &&
                  ($option_ref->{xmlns_stack}->[-1] ne
                      $option_ref->{xmlns_stack}->[-2])) {
                join q{}, $_->start_tag({
                            name => $name,
                            xmlns => $option_ref->{xmlns_stack}->[-1],
                            %{$option_ref}
                          }),
                     $_->serialize($option_ref),
                     $_->end_tag({name => $name , %{$option_ref}});
              } else {
                # PATCH Determine if xsi:type is required.
                my $refname = ref($_);
                my $classname = $CLASSES_OF->{$class}->{$name};
                if ($classname && $classname ne ref($_)) {
                  my $xsitypens = {};
                  if ($option_ref->{xmlns_stack}->[-1] ne $_->get_xmlns()){
                    $xsitypens->{name} = "xns";
                    $xsitypens->{value} = $_->get_xmlns();
                    $option_ref->{xsitypens} = $xsitypens;
                  }
                  my $package_name = ref($_);
                  $package_name =~ /^.*::(.*)$/;
                  my $xsi_type = $1;
                  $option_ref->{xsitype} =
                      ($xsitypens->{name}?$xsitypens->{name} . ":" : "") .
                      "$xsi_type";
                } else {
                  delete $option_ref->{xsitype};
                }

                # Checks to see if namespace is required because it is an
                # inherited attribute on a different namespace.
                my $class_isa = $class . "::ISA";
                my @class_parents = @$class_isa;
                my $requires_namespace = 0;
                foreach my $parent (@class_parents) {
                  my %parent_elements =
                      map { $_ => 1 } @{$ELEMENTS_FROM->{$parent}};
                  my $parent_has_element = exists($parent_elements{$name});

                  if ($parent_has_element) {
                    my $parent_xns;
                    eval "\$parent_xns = " . $parent. "::get_xmlns()";
                    if ($parent_xns ne $option_ref->{xmlns_stack}->[-1]) {
                      $requires_namespace = 1;
                    }
                  }
                }

                if ($requires_namespace) {
                  join q{}, $_->start_tag({name => $name,
                                           xmlns => $_->get_xmlns(),
                                           %{$option_ref}}),
                       $_->serialize($option_ref),
                       $_->end_tag({name => $name , %{$option_ref}});
                } else {
                  join q{}, $_->start_tag({name => $name, %{$option_ref}}),
                       $_->serialize($option_ref),
                       $_->end_tag({name => $name , %{$option_ref}});
                }
                # END PATCH
              }
            } else {
              my $set_xmlns = delete $option_ref->{xmlns};

              join q{},
                   $_->start_tag({
                     name => $name,
                     %{$option_ref},
                     (!defined $set_xmlns)?(xmlns => ""):()
                   }),
                   $_->serialize({%{$option_ref}, xmlns => ""}),
                   $_->end_tag({name => $name , %{$option_ref}});
            }
          }
        } @{$element}
      } else {
        q{};
      }
    } (@{$ELEMENTS_FROM->{$class}});
  };

  if (!$class->isa('SOAP::WSDL::XSD::Typelib::AttributeSet')) {
    *{"$class\::serialize"} =
        \&SOAP::WSDL::XSD::Typelib::ComplexType::__serialize_complex;
  };
}

# Added to support hash to object serialization.
# A special xsi_type attribute name has been reserved to specify subtype of
# the object been passed when using hashes.
# PATCH This entire method was added to the class.
sub _hash_to_object {
  my ($type, $hash) = @_;

  if ($hash->{"xsi_type"}) {
    my $base_type = $type;
    my $xsi_type = $hash->{"xsi_type"};
    $type = substr($type, 0, rindex($type, "::") + 2) . $xsi_type;
    eval("require $type");
    die croak "xsi_type $xsi_type not found" if $@;
    my $instance = $type->new($hash);
    die croak "xsi_type $xsi_type must inherit from " . "$type"
        if not $instance->isa($base_type);
    return $instance;
  } else {
    return $type->new($hash);
  }
}
# END PATCH

# Redefining as_hash_ref method to correctly map all object properties to a
# hash structure.
sub as_hash_ref {
  my $self = $_[0];
  my $attributes_ref = $self->__get_object_attributes($self);

  my $AS_HASH_REF_WITHOUT_ATTRIBUTES =
      *SOAP::WSDL::XSD::Typelib::ComplexType::AS_HASH_REF_WITHOUT_ATTRIBUTES;
  my $xml_attr_of =
      *SOAP::WSDL::XSD::Typelib::ComplexType::xml_attr_of;

  my $hash_of_ref = {};
  if ($_[0]->isa('SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType')) {
    $hash_of_ref->{value} = $_[0]->get_value();
  } else {
    foreach my $attribute (keys %{$attributes_ref}) {
      next if not defined $attributes_ref->{$attribute}->{${$_[0]}};
      my $value = $attributes_ref->{$attribute}->{${$_[0]}};
      # PATCH normalizing the attribute name
      $attribute =~ s/__/./g;
      # END PATCH
      $hash_of_ref->{$attribute} = blessed $value
          ? $value->isa('SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType')
              ? $value->get_value()
              # PATCH returning the value no need to recurse
              : $value
              # END PATCH
          : ref $value eq 'ARRAY'
              ? [map {
                  $_->isa('SOAP::WSDL::XSD::Typelib::Builtin::anySimpleType')
                      ? $_->get_value()
                      # PATCH returning the object no need to recurse
                      : $_
                      # END PATCH
                } @{$value}]
              : die "Neither blessed obj nor list ref";
    };
  }

  return $hash_of_ref if $_[1] or $AS_HASH_REF_WITHOUT_ATTRIBUTES;

  if (exists $xml_attr_of{${$_[0]}}) {
    $hash_of_ref->{xmlattr} = $xml_attr_of{${$_[0]}}->as_hash_ref();
  }

  return $hash_of_ref;
}

# PATCH To retrieve object attributes mapping including inherited.
sub __get_object_attributes {
  my $object = $_[1];
  my @types = (ref $object);
  my %attributes;

  while (my $type = pop(@types)) {
    eval("require $type");
    my $type_bases_name = $type . "::ISA";
    push @types, @$type_bases_name;
    my $attributes_ref = $ATTRIBUTES_OF{$type};
    for my $key (keys %$attributes_ref) {
      my $value = $attributes_ref->{$key};
      if (not exists $attributes{$key}) {
        $attributes{$key} = $value;
      }
    }
  }
  return \%attributes;
}
# END PATCH

# PATCH To retrieve attributes xml names including inherited.
sub __get_object_names {
  my $object = $_[1];
  my @types = (ref $object);
  my %names;

  while (my $type = pop(@types)) {
    eval("require $type");
    my $type_bases_name = $type . "::ISA";
    push @types, @$type_bases_name;
    my $names_ref = $NAMES_OF{$type};
    for my $key (keys %$names_ref) {
      my $value = $names_ref->{$key};
      if (not exists $names{$key}) {
        $names{$key} = $value;
      }
    }
  }
  return \%names;
}
# END PATCH

# PATCH Method for the client to find objects in the tree based on an a partial
# support of XPath expressions.
sub find {
  my ($self, $xpath_expr) = @_;

  my $parser_node =
      Google::Ads::Common::XPathSAXParser::get_node_from_object($self);

  my @return_list = ();
  if (defined $parser_node) {
    my $node_set = $parser_node->find($xpath_expr);
    foreach my $node ($node_set->get_nodelist()) {
      my $soap_object =
          Google::Ads::Common::XPathSAXParser::get_object_from_node($node);
      if (defined $soap_object) {
        push @return_list, $soap_object;
      }
    }
  }

  return \@return_list;
}
# END PATCH

# PATCH Setting an alias of find -> valueof for backwards compatibility with
# the old version of the client library.
*SOAP::WSDL::XSD::Typelib::ComplexType::valueof =
    \&SOAP::WSDL::XSD::Typelib::ComplexType::find;
# END PATCH

# PATCH Overloading hash casting routine for ComplexType, so all complex types
# can behave as hashes.
use overload (
  '%{}' => 'as_hash_ref',
  fallback => 1,
);
# END PATCH

package Google::Ads::ThirdParty::SOAPWSDLPatches;

# Empty package - this file only contains overrides of other packages.

return 1;
