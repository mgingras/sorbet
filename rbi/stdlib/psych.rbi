# typed: __STDLIB_INTERNAL

###
# = Overview
#
# Psych is a YAML parser and emitter.
# Psych leverages libyaml [Home page: https://pyyaml.org/wiki/LibYAML]
# or [HG repo: https://bitbucket.org/xi/libyaml] for its YAML parsing
# and emitting capabilities. In addition to wrapping libyaml, Psych also
# knows how to serialize and de-serialize most Ruby objects to and from
# the YAML format.
#
# = I NEED TO PARSE OR EMIT YAML RIGHT NOW!
#
#   # Parse some YAML
#   Psych.load("--- foo") # => "foo"
#
#   # Emit some YAML
#   Psych.dump("foo")     # => "--- foo\n...\n"
#   { :a => 'b'}.to_yaml  # => "---\n:a: b\n"
#
# Got more time on your hands?  Keep on reading!
#
# == YAML Parsing
#
# Psych provides a range of interfaces for parsing a YAML document ranging from
# low level to high level, depending on your parsing needs.  At the lowest
# level, is an event based parser.  Mid level is access to the raw YAML AST,
# and at the highest level is the ability to unmarshal YAML to Ruby objects.
#
# == YAML Emitting
#
# Psych provides a range of interfaces ranging from low to high level for
# producing YAML documents.  Very similar to the YAML parsing interfaces, Psych
# provides at the lowest level, an event based system, mid-level is building
# a YAML AST, and the highest level is converting a Ruby object straight to
# a YAML document.
#
# == High-level API
#
# === Parsing
#
# The high level YAML parser provided by Psych simply takes YAML as input and
# returns a Ruby data structure.  For information on using the high level parser
# see Psych.load
#
# ==== Reading from a string
#
#   Psych.load("--- a")             # => 'a'
#   Psych.load("---\n - a\n - b")   # => ['a', 'b']
#
# ==== Reading from a file
#
#   Psych.load_file("database.yml")
#
# ==== Exception handling
#
#   begin
#     # The second argument changes only the exception contents
#     Psych.parse("--- `", "file.txt")
#   rescue Psych::SyntaxError => ex
#     ex.file    # => 'file.txt'
#     ex.message # => "(file.txt): found character that cannot start any token"
#   end
#
# === Emitting
#
# The high level emitter has the easiest interface.  Psych simply takes a Ruby
# data structure and converts it to a YAML document.  See Psych.dump for more
# information on dumping a Ruby data structure.
#
# ==== Writing to a string
#
#   # Dump an array, get back a YAML string
#   Psych.dump(['a', 'b'])  # => "---\n- a\n- b\n"
#
#   # Dump an array to an IO object
#   Psych.dump(['a', 'b'], StringIO.new)  # => #<StringIO:0x000001009d0890>
#
#   # Dump an array with indentation set
#   Psych.dump(['a', ['b']], :indentation => 3) # => "---\n- a\n-  - b\n"
#
#   # Dump an array to an IO with indentation set
#   Psych.dump(['a', ['b']], StringIO.new, :indentation => 3)
#
# ==== Writing to a file
#
# Currently there is no direct API for dumping Ruby structure to file:
#
#   File.open('database.yml', 'w') do |file|
#     file.write(Psych.dump(['a', 'b']))
#   end
#
# == Mid-level API
#
# === Parsing
#
# Psych provides access to an AST produced from parsing a YAML document.  This
# tree is built using the Psych::Parser and Psych::TreeBuilder.  The AST can
# be examined and manipulated freely.  Please see Psych::parse_stream,
# Psych::Nodes, and Psych::Nodes::Node for more information on dealing with
# YAML syntax trees.
#
# ==== Reading from a string
#
#   # Returns Psych::Nodes::Stream
#   Psych.parse_stream("---\n - a\n - b")
#
#   # Returns Psych::Nodes::Document
#   Psych.parse("---\n - a\n - b")
#
# ==== Reading from a file
#
#   # Returns Psych::Nodes::Stream
#   Psych.parse_stream(File.read('database.yml'))
#
#   # Returns Psych::Nodes::Document
#   Psych.parse_file('database.yml')
#
# ==== Exception handling
#
#   begin
#     # The second argument changes only the exception contents
#     Psych.parse("--- `", "file.txt")
#   rescue Psych::SyntaxError => ex
#     ex.file    # => 'file.txt'
#     ex.message # => "(file.txt): found character that cannot start any token"
#   end
#
# === Emitting
#
# At the mid level is building an AST.  This AST is exactly the same as the AST
# used when parsing a YAML document.  Users can build an AST by hand and the
# AST knows how to emit itself as a YAML document.  See Psych::Nodes,
# Psych::Nodes::Node, and Psych::TreeBuilder for more information on building
# a YAML AST.
#
# ==== Writing to a string
#
#   # We need Psych::Nodes::Stream (not Psych::Nodes::Document)
#   stream = Psych.parse_stream("---\n - a\n - b")
#
#   stream.to_yaml # => "---\n- a\n- b\n"
#
# ==== Writing to a file
#
#   # We need Psych::Nodes::Stream (not Psych::Nodes::Document)
#   stream = Psych.parse_stream(File.read('database.yml'))
#
#   File.open('database.yml', 'w') do |file|
#     file.write(stream.to_yaml)
#   end
#
# == Low-level API
#
# === Parsing
#
# The lowest level parser should be used when the YAML input is already known,
# and the developer does not want to pay the price of building an AST or
# automatic detection and conversion to Ruby objects.  See Psych::Parser for
# more information on using the event based parser.
#
# ==== Reading to Psych::Nodes::Stream structure
#
#   parser = Psych::Parser.new(TreeBuilder.new) # => #<Psych::Parser>
#   parser = Psych.parser                       # it's an alias for the above
#
#   parser.parse("---\n - a\n - b")             # => #<Psych::Parser>
#   parser.handler                              # => #<Psych::TreeBuilder>
#   parser.handler.root                         # => #<Psych::Nodes::Stream>
#
# ==== Receiving an events stream
#
#   recorder = Psych::Handlers::Recorder.new
#   parser = Psych::Parser.new(recorder)
#
#   parser.parse("---\n - a\n - b")
#   recorder.events # => [list of [event, args] lists]
#                   # event is one of: Psych::Handler::EVENTS
#                   # args are the arguments passed to the event
#
# === Emitting
#
# The lowest level emitter is an event based system.  Events are sent to a
# Psych::Emitter object.  That object knows how to convert the events to a YAML
# document.  This interface should be used when document format is known in
# advance or speed is a concern.  See Psych::Emitter for more information.
#
# ==== Writing to a Ruby structure
#
#   Psych.parser.parse("--- a")       # => #<Psych::Parser>
#
#   parser.handler.first              # => #<Psych::Nodes::Stream>
#   parser.handler.first.to_ruby      # => ["a"]
#
#   parser.handler.root.first         # => #<Psych::Nodes::Document>
#   parser.handler.root.first.to_ruby # => "a"
#
#   # You can instantiate an Emitter manually
#   Psych::Visitors::ToRuby.new.accept(parser.handler.root.first)
#   # => "a"

module Psych
  # The version of libyaml Psych is using
  LIBYAML_VERSION = T.let(T.unsafe(nil), String)
  # Deprecation guard
  NOT_GIVEN = T.let(T.unsafe(nil), Object)

  ###
  # Load +yaml+ in to a Ruby data structure.  If multiple documents are
  # provided, the object contained in the first document will be returned.
  # +filename+ will be used in the exception message if any exception
  # is raised while parsing.  If +yaml+ is empty, it returns
  # the specified +fallback+ return value, which defaults to +false+.
  #
  # Raises a Psych::SyntaxError when a YAML syntax error is detected.
  #
  # Example:
  #
  #   Psych.load("--- a")             # => 'a'
  #   Psych.load("---\n - a\n - b")   # => ['a', 'b']
  #
  #   begin
  #     Psych.load("--- `", filename: "file.txt")
  #   rescue Psych::SyntaxError => ex
  #     ex.file    # => 'file.txt'
  #     ex.message # => "(file.txt): found character that cannot start any token"
  #   end
  #
  # When the optional +symbolize_names+ keyword argument is set to a
  # true value, returns symbols for keys in Hash objects (default: strings).
  #
  #   Psych.load("---\n foo: bar")                         # => {"foo"=>"bar"}
  #   Psych.load("---\n foo: bar", symbolize_names: true)  # => {:foo=>"bar"}
  #
  # Raises a TypeError when `yaml` parameter is NilClass
  #
  # NOTE: This method *should not* be used to parse untrusted documents, such as
  # YAML documents that are supplied via user input.  Instead, please use the
  # safe_load method.
  #
  sig do
    params(
      yaml: T.any(String, StringIO),
      legacy_filename: Object,
      filename: T.nilable(String),
      fallback: T.untyped,
      symbolize_names: T::Boolean,
    )
    .returns(T.untyped)
  end
  def self.load(yaml, legacy_filename = T.unsafe(nil), filename: T.unsafe(nil), fallback: T.unsafe(nil), symbolize_names: T.unsafe(nil)); end

  ###
  # Safely load the yaml string in +yaml+.  By default, only the following
  # classes are allowed to be deserialized:
  #
  # * TrueClass
  # * FalseClass
  # * NilClass
  # * Numeric
  # * String
  # * Array
  # * Hash
  #
  # Recursive data structures are not allowed by default.  Arbitrary classes
  # can be allowed by adding those classes to the +permitted_classes+ keyword argument.  They are
  # additive.  For example, to allow Date deserialization:
  #
  #   Psych.safe_load(yaml, permitted_classes: [Date])
  #
  # Now the Date class can be loaded in addition to the classes listed above.
  #
  # Aliases can be explicitly allowed by changing the +aliases+ keyword argument.
  # For example:
  #
  #   x = []
  #   x << x
  #   yaml = Psych.dump x
  #   Psych.safe_load yaml               # => raises an exception
  #   Psych.safe_load yaml, aliases: true # => loads the aliases
  #
  # A Psych::DisallowedClass exception will be raised if the yaml contains a
  # class that isn't in the +permitted_classes+ list.
  #
  # A Psych::BadAlias exception will be raised if the yaml contains aliases
  # but the +aliases+ keyword argument is set to false.
  #
  # +filename+ will be used in the exception message if any exception is raised
  # while parsing.
  #
  # When the optional +symbolize_names+ keyword argument is set to a
  # true value, returns symbols for keys in Hash objects (default: strings).
  #
  #   Psych.safe_load("---\n foo: bar")                         # => {"foo"=>"bar"}
  #   Psych.safe_load("---\n foo: bar", symbolize_names: true)  # => {:foo=>"bar"}
  #
  sig do
    params(
      yaml: T.any(String, StringIO),
      legacy_permitted_classes: Object,
      legacy_permitted_symbols: Object,
      legacy_aliases: Object,
      legacy_filename: Object,
      permitted_classes: T::Array[Class],
      permitted_symbols: T::Array[Symbol],
      aliases: T::Boolean,
      filename: T.nilable(String),
      fallback: T.untyped,
      symbolize_names: T::Boolean,
    )
    .returns(T.untyped)
  end
  def self.safe_load(yaml, legacy_permitted_classes = T.unsafe(nil), legacy_permitted_symbols = T.unsafe(nil), legacy_aliases = T.unsafe(nil), legacy_filename = T.unsafe(nil), permitted_classes: T.unsafe(nil), permitted_symbols: T.unsafe(nil), aliases: T.unsafe(nil), filename: T.unsafe(nil), fallback: T.unsafe(nil), symbolize_names: T.unsafe(nil)); end

  ###
  # Parse a YAML string in +yaml+.  Returns the Psych::Nodes::Document.
  # +filename+ is used in the exception message if a Psych::SyntaxError is
  # raised.
  #
  # Raises a Psych::SyntaxError when a YAML syntax error is detected.
  #
  # Example:
  #
  #   Psych.parse("---\n - a\n - b") # => #<Psych::Nodes::Document:0x00>
  #
  #   begin
  #     Psych.parse("--- `", filename: "file.txt")
  #   rescue Psych::SyntaxError => ex
  #     ex.file    # => 'file.txt'
  #     ex.message # => "(file.txt): found character that cannot start any token"
  #   end
  #
  # See Psych::Nodes for more information about YAML AST.
  sig do
    params(
      yaml: T.any(String, StringIO),
      legacy_filename: Object,
      filename: T.nilable(String),
      fallback: T.untyped,
    )
    .returns(T.untyped)
  end
  def self.parse(yaml, legacy_filename = T.unsafe(nil), filename: T.unsafe(nil), fallback: T.unsafe(nil)); end

  ###
  # Parse a file at +filename+. Returns the Psych::Nodes::Document.
  #
  # Raises a Psych::SyntaxError when a YAML syntax error is detected.
  sig do
    params(
      filename: String,
      fallback: T.untyped,
    )
    .returns(T.untyped)
  end
  def self.parse_file(filename, fallback: T.unsafe(nil)); end

  ###
  # Returns a default parser
  sig { returns(Psych::Parser) }
  def self.parser; end

  ###
  # Parse a YAML string in +yaml+.  Returns the Psych::Nodes::Stream.
  # This method can handle multiple YAML documents contained in +yaml+.
  # +filename+ is used in the exception message if a Psych::SyntaxError is
  # raised.
  #
  # If a block is given, a Psych::Nodes::Document node will be yielded to the
  # block as it's being parsed.
  #
  # Raises a Psych::SyntaxError when a YAML syntax error is detected.
  #
  # Example:
  #
  #   Psych.parse_stream("---\n - a\n - b") # => #<Psych::Nodes::Stream:0x00>
  #
  #   Psych.parse_stream("--- a\n--- b") do |node|
  #     node # => #<Psych::Nodes::Document:0x00>
  #   end
  #
  #   begin
  #     Psych.parse_stream("--- `", filename: "file.txt")
  #   rescue Psych::SyntaxError => ex
  #     ex.file    # => 'file.txt'
  #     ex.message # => "(file.txt): found character that cannot start any token"
  #   end
  #
  # Raises a TypeError when NilClass is passed.
  #
  # See Psych::Nodes for more information about YAML AST.
  sig do
    params(
      yaml: T.any(String, StringIO),
      legacy_filename: Object,
      filename: T.nilable(String),
      block: T.nilable(T.proc.params(node: Psych::Nodes::Document).void),
    )
    .returns(Psych::Nodes::Stream)
  end
  def self.parse_stream(yaml, legacy_filename = T.unsafe(nil), filename: T.unsafe(nil), &block); end

  ###
  # call-seq:
  #   Psych.dump(o)               -> string of yaml
  #   Psych.dump(o, options)      -> string of yaml
  #   Psych.dump(o, io)           -> io object passed in
  #   Psych.dump(o, io, options)  -> io object passed in
  #
  # Dump Ruby object +o+ to a YAML string.  Optional +options+ may be passed in
  # to control the output format.  If an IO object is passed in, the YAML will
  # be dumped to that IO object.
  #
  # Currently supported options are:
  #
  # [<tt>:indentation</tt>]   Number of space characters used to indent.
  #                           Acceptable value should be in <tt>0..9</tt> range,
  #                           otherwise option is ignored.
  #
  #                           Default: <tt>2</tt>.
  # [<tt>:line_width</tt>]    Max character to wrap line at.
  #
  #                           Default: <tt>0</tt> (meaning "wrap at 81").
  # [<tt>:canonical</tt>]     Write "canonical" YAML form (very verbose, yet
  #                           strictly formal).
  #
  #                           Default: <tt>false</tt>.
  # [<tt>:header</tt>]        Write <tt>%YAML [version]</tt> at the beginning of document.
  #
  #                           Default: <tt>false</tt>.
  #
  # Example:
  #
  #   # Dump an array, get back a YAML string
  #   Psych.dump(['a', 'b'])  # => "---\n- a\n- b\n"
  #
  #   # Dump an array to an IO object
  #   Psych.dump(['a', 'b'], StringIO.new)  # => #<StringIO:0x000001009d0890>
  #
  #   # Dump an array with indentation set
  #   Psych.dump(['a', ['b']], indentation: 3) # => "---\n- a\n-  - b\n"
  #
  #   # Dump an array to an IO with indentation set
  #   Psych.dump(['a', ['b']], StringIO.new, indentation: 3)
  sig do
    params(
      o: T.untyped,
      io: T.untyped,
      options: T::Hash[Symbol, T.untyped],
    )
    .returns(T.untyped)
  end
  def self.dump(o, io = T.unsafe(nil), options = T.unsafe(nil)); end

  ###
  # Dump a list of objects as separate documents to a document stream.
  #
  # Example:
  #
  #   Psych.dump_stream("foo\n  ", {}) # => "--- ! \"foo\\n  \"\n--- {}\n"
  sig { params(objects: T.untyped).returns(T.untyped) }
  def self.dump_stream(*objects); end

  ###
  # Dump Ruby +object+ to a JSON string.
  sig { params(object: T.untyped).returns(String) }
  def self.to_json(object); end

  ###
  # Load multiple documents given in +yaml+.  Returns the parsed documents
  # as a list.  If a block is given, each document will be converted to Ruby
  # and passed to the block during parsing
  #
  # Example:
  #
  #   Psych.load_stream("--- foo\n...\n--- bar\n...") # => ['foo', 'bar']
  #
  #   list = []
  #   Psych.load_stream("--- foo\n...\n--- bar\n...") do |ruby|
  #     list << ruby
  #   end
  #   list # => ['foo', 'bar']
  #
  sig do
    params(
      yaml: T.any(String, StringIO),
      legacy_filename: Object,
      filename: T.nilable(String),
      fallback: T.untyped,
    )
    .returns(T::Array[T.untyped])
  end
  def self.load_stream(yaml, legacy_filename = T.unsafe(nil), filename: T.unsafe(nil), fallback: T.unsafe(nil)); end

  ###
  # Load the document contained in +filename+.  Returns the yaml contained in
  # +filename+ as a Ruby object, or if the file is empty, it returns
  # the specified +fallback+ return value, which defaults to +false+.
  sig { params(filename: String, fallback: T.untyped).returns(T.untyped) }
  def self.load_file(filename, fallback: false); end
end

class Psych::Handler
end

class Psych::Nodes::Node
  include Enumerable
  extend T::Generic
  Elem = type_member(:out, fixed: T.untyped)
end

class Psych::Nodes::Document < Psych::Nodes::Node
  include Enumerable
  extend T::Generic
  Elem = type_member(:out, fixed: T.untyped)
end

class Psych::Nodes::Stream < Psych::Nodes::Node
  include Enumerable
  extend T::Generic
  Elem = type_member(:out, fixed: T.untyped)
end

class Psych::Parser
end

class Psych::Visitors::Visitor
end

class Psych::Visitors::ToRuby < Psych::Visitors::Visitor
end