module Crinja::Parser
  module BuildTag
    def build_tag_node(start_token)
      name_token = token_stream.next_token
      raise "Tag musst have a name token" unless name_token.kind == Kind::NAME

      tag = template.env.tags[name_token.value]

      if tag.nil?
        raise TemplateSyntaxError.new(start_token, "unknown tag: #{name_token.value}")
      end

      if tag.is_a?(Tag::EndTag)
        build_end_tag_node(start_token, tag)
        return nil
      end

      arguments = [] of Statement

      root = Statement::MultiRoot.new(start_token)

      statement_parser = StatementParser.new(self, root)
      statement_parser.expected_end_token = Kind::TAG_END

      statement_parser.build

      end_token = current_token
      node = Node::Tag.new(start_token, name_token, end_token, tag, root.varargs, root.kwargs)
      node.parent = @parent.as(Node)

      set_trim_for_last_sibling(node.trim_left?, true)

      unless node.end_name.nil?
        @parent << node
        @parent = node
        return nil
      end

      node
    end

    def build_end_tag_node(start_token, tag)
      name_token = current_token

      end_token = next_token
      raise "expected closing tag sequence `%}` for end tag #{tag}" unless end_token.kind == Kind::TAG_END

      while !@parent.is_a?(Node::Root)
        parent_tag = @parent.as(Node::Tag)
        @parent = @parent.parent.not_nil!

        if parent_tag.end_name == tag.name
          set_trim_for_last_child(start_token.trim_left, true)
          end_tag = Node::Tag.new(start_token, name_token, end_token, tag, Array(Statement).new, Hash(String, Statement).new)
          parent_tag.end_tag = end_tag
          break
        else
          raise TemplateSyntaxError.new(start_token, "Mismatched end tag, expected: #{parent_tag.end_name} got #{tag.name}")
        end
      end
    end
  end
end