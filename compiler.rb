#!/usr/bin ruby

class Tokenizer
  TOKEN_TYPES = [
    [:def, /\bdef\b/],
    [:end, /\bend\b/],
    [:identifier, /\b[a-zA-Z]+\b/],
    [:integer, /\b[0-9]+\b/],
    [:var_name, /\b[a-zA-Z]+\b/],
    [:open_paren, /\(/],
    [:close_paren, /\)/],
    [:assignment_operator, /\=/],
    [:expression_terminator, /\;/],
    [:separator, /\,/]
  ] 

  def initialize(code)
    @code = code 
  end

  def tokenize
    tokens = [] 
    until @code.empty?
      tokens << tokenize_single_token
    end
    tokens
  end

  def tokenize_single_token
    TOKEN_TYPES.each do |type, regex|
      regex = /\A(#{regex})/
      if @code =~ regex
        token_value = $1
        @code = @code[token_value.length..-1].strip
        return Token.new(type, token_value)
      end
    end

    raise RuntimeError.new("Couldn't match token on #{@code.inspect}")
  end
end

Token = Struct.new(:type, :value)

class Parser
  def initialize(tokens)
    @tokens = tokens
  end

  def parse
    nodes = []
    nodes << parse_variable_assignment if check_next_token_type(:identifier)
    nodes << parse_def if check_next_token_type(:def)
    nodes
  end

  def parse_variable_assignment
    var_name = consume(:identifier)
    consume(:assignment_operator)
    var_value = consume(:integer)
    consume(:expression_terminator)
    VarAssignmentNode.new(var_name.value, var_value.value)
  end

  def parse_def
    consume(:def)
    identifier = consume(:identifier)
    arg_names = parse_arg_names
    return_value = consume_body
    consume(:end)
    DefNode.new(identifier.value, arg_names, return_value.value)
  end

  def parse_arg_names
    consume(:open_paren)
    args = []
    args = addAnyArgs(args)
    consume(:close_paren)
    args
  end

  def addAnyArgs(args) 
    args << consume(:identifier).value if check_next_token_type(:identifier)
    if check_next_token_type(:separator)
      consume(:separator)
      addAnyArgs(args)
    end
    args
  end

  def check_next_token_type(expected_type)
    @tokens[0].type == (expected_type)
  end

  def consume_body
    if @tokens[0].type == :integer || @tokens[0].type == :identifier
      @tokens.shift
    else
      raise RuntimeError.new("expected #{expected_type} but got #{@tokens[0].type}")
    end
  end

  def consume(expected_type)
    if @tokens[0].type == expected_type 
      @tokens.shift
    else
      raise RuntimeError.new("expected #{expected_type} but got #{@tokens[0].type}")
    end
  end
end

DefNode = Struct.new(:name, :arg_names, :return_value)
VarAssignmentNode = Struct.new(:var_name, :var_value)

class Generator
  def generate(nodes)
    str = ''
    nodes.each do |node|
        if node.is_a?(VarAssignmentNode)
          str += "var #{node.var_name} = #{node.var_value};"
        end
        if node.is_a?(DefNode)
          str += "function #{node.name} (#{args_string(node.arg_names)}) { return #{node.return_value} }"
        end
    end
    str
  end

  def args_string(arg_names)
    str = ''
    arg_names.each_with_index do |arg_name, index|
      str += arg_name if index == 0
      str += ", #{arg_name}" if index > 0
    end
    str
  end
end


tokens = Tokenizer.new(File.read("test.src")).tokenize
#puts tokens.map(&:inspect).join("\n")

tree = Parser.new(tokens).parse
#puts tree
puts Generator.new.generate(tree)
