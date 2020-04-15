# frozen_string_literal: true

require "test_helper"

module ConstantResolver
  class ResolverTest < Minitest::Test
    AUTOVIVIFIED = "autovivified"

    class AutoloaderStub
      def initialize(path_map = {})
        @path_map = path_map
      end

      def path_for(fully_qualified_constant)
        @path_map[fully_qualified_constant]
      end

      def autovivified?(fully_qualified_constant)
        @path_map[fully_qualified_constant] == AUTOVIVIFIED
      end
    end

    def setup
      @stub_constant_definitions = stub(each_definition_for: nil)
    end

    def test_can_resolve_fully_qualified_constant_if_found
      autoloader = AutoloaderStub.new(
        "::Foo" => AUTOVIVIFIED,
        "::Foo::Bar" => "foo/bar.rb",
      )
      resolver = Resolver.new(autoloader, constant_definitions: @stub_constant_definitions)

      constant_context = resolver.resolve("::Foo::Bar")

      assert_equal("::Foo::Bar", constant_context.name)
      assert_equal("foo/bar.rb", constant_context.location)
    end

    def test_can_resolve_fully_qualified_constant_with_namespace_path_if_found
      autoloader = AutoloaderStub.new(
        "::Foo" => AUTOVIVIFIED,
        "::Foo::Bar" => "foo/bar.rb",
      )
      resolver = Resolver.new(autoloader, constant_definitions: @stub_constant_definitions)

      constant_context = resolver.resolve("::Foo::Bar", namespace_path: ["Foo"])

      assert_equal("::Foo::Bar", constant_context.name)
      assert_equal("foo/bar.rb", constant_context.location)
    end

    def test_can_resolve_relative_constant_if_found
      autoloader = AutoloaderStub.new(
        "::Foo" => AUTOVIVIFIED,
        "::Foo::Bar" => "foo/bar.rb",
      )
      resolver = Resolver.new(autoloader, constant_definitions: @stub_constant_definitions)

      constant_context = resolver.resolve("Bar", namespace_path: ["Foo"])

      assert_equal("::Foo::Bar", constant_context.name)
      assert_equal("foo/bar.rb", constant_context.location)
    end

    def test_can_resolve_constant_in_grandparent_namespace
      autoloader = AutoloaderStub.new(
        "::Foo" => "foo.rb",
        "::Foo::Bar" => "foo.rb",
        "::Foo::Bar::Spam" => "foo.rb",
      )
      resolver = Resolver.new(autoloader, constant_definitions: @stub_constant_definitions)

      constant_context = resolver.resolve("Spam", namespace_path: ["Foo", "Bar"])

      assert_equal("::Foo::Bar::Spam", constant_context.name)
      assert_equal("foo.rb", constant_context.location)
    end

    def test_does_not_resolve_compact_constant_even_if_it_exists_at_a_higher_level
      autoloader = AutoloaderStub.new(
        "::Bar" => "bar.rb",
        "::Bar::Spam" => "bar/spam.rb",
        "::NotBar" => AUTOVIVIFIED,
        "::NotBar::Bar" => "not_bar/bar.rb",
        "::NotBar::Bar::Eggs" => "not_bar/bar/eggs.rb",
      )
      resolver = Resolver.new(autoloader, constant_definitions: @stub_constant_definitions)

      constant_context = resolver.resolve("Bar::Spam", namespace_path: ["NotBar"])

      assert_nil(constant_context)
    end

    def test_returns_nil_when_cannot_resolve_constant_to_path
      autoloader = AutoloaderStub.new
      resolver = Resolver.new(autoloader, constant_definitions: @stub_constant_definitions)

      constant_context = resolver.resolve("::Foo::Bar", namespace_path: ["Foo"])

      assert_nil(constant_context)
    end
  end
end
