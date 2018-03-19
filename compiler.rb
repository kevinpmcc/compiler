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
    nodes << parse_expression if check_next_token_type(:identifier)
    return nodes if @tokens.empty?
    nodes << parse_def if check_next_token_type(:def)
    nodes
  end

  def parse_variable_assignment
    var_name = VarRefNode.new(consume(:identifier).value)
    consume(:assignment_operator)
    var_value = IntegerNode.new(consume(:integer).value)
    VarAssignmentNode.new(var_name, var_value)
  end

  def parse_def
    consume(:def)
    identifier = consume(:identifier)
    arg_names = parse_arg_names
    body = parse_expression
    consume(:end)
    DefNode.new(identifier.value, arg_names, body)
  end

  def parse_expression
    if check_next_token_type(:integer) 
      IntegerNode.new(consume(:integer).value)
    elsif check_next_token_type(:identifier) && @tokens[1].type == :open_paren
       parse_function_call
    elsif check_next_token_type(:identifier) && @tokens[1].type == :assignment_operator
       parse_variable_assignment 
    elsif check_next_token_type(:identifier) 
      VarRefNode.new(consume(:identifier).value)
    else
      raise RuntimeError.new("expected integer or identifier but got #{@tokens[0].type}")
    end
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

  def parse_arg_expressions
    consume(:open_paren)
    args = []
    args = addAnyArgExpressions(args)
    consume(:close_paren)
    args
  end

  def addAnyArgExpressions(args)
    return args if check_next_token_type(:close_paren)
    args << consume(:identifier).value
    if check_next_token_type(:separator)
      consume(:separator)
      addAnyArgExpressions(args)
    end
    args
  end

  def check_next_token_type(expected_type)
    @tokens[0].type == expected_type
  end

  def parse_function_call
    function_name = VarRefNode.new(consume(:identifier).value)
    arg_expressions = parse_arg_expressions
    FunctionCallNode.new(function_name, arg_expressions)
  end

  def consume(expected_type)
    if @tokens[0].type == expected_type 
      @tokens.shift
    else
      raise RuntimeError.new("expected #{expected_type} but got #{@tokens[0].type}")
    end
  end
end

DefNode = Struct.new(:name, :arg_names, :body)
VarAssignmentNode = Struct.new(:var_name, :var_value)
FunctionCallNode = Struct.new(:name, :arg_expressions)
IntegerNode = Struct.new(:value)
VarRefNode = Struct.new(:value)

class Generator
  def generate(nodes)
    str = ''
    nodes.each do |node|
      str += generate_single_node(node)
    end
    str
  end

  def generate_single_node(node)
    case node
    when VarAssignmentNode
      "var #{generate_single_node(node.var_name)} = #{generate_single_node(node.var_value)};"
    when DefNode
      "function #{node.name} (#{node.arg_names.join(', ')}) { return #{generate_single_node(node.body)} }"
    when FunctionCallNode
      "#{generate_single_node(node.name)}(#{node.arg_expressions.join(', ')})"
    when IntegerNode
      node.value
    when VarRefNode
      node.value
    end
  end
end


# tokens = Tokenizer.new(File.read("test.src")).tokenize
# #puts tokens.map(&:inspect).join("\n")

# tree = Parser.new(tokens).parse
# #puts tree
# generated =  Generator.new.generate(tree)

# RUNTIME = "function add(x, y) { return x + y };"
# TEST = "console.log(newFunction(17))"
# puts [RUNTIME, generated, TEST].join("\n")

