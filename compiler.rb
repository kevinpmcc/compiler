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
    body = parse_expression
    consume(:end)
    DefNode.new(identifier.value, arg_names, body)
  end

  def parse_expression
    if check_next_token_type(:integer) 
      @tokens.shift
    elsif check_next_token_type(:identifier) && @tokens[1].type == :open_paren
       parse_function_call
    elsif check_next_token_type(:identifier) 
       @tokens.shift
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
    return if check_next_token_type(:close_paren)
    args << parse_expression
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
    function_name = @tokens.shift
    arg_expressions = parse_arg_expressions
    FunctionCall.new(function_name, arg_expressions)
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
FunctionCall = Struct.new(:name, :arg_expressions)

class Generator
  def generate(nodes)
    str = ''
    nodes.each do |node|
        if node.is_a?(VarAssignmentNode)
          str += "var #{node.var_name} = #{node.var_value};"
        end
        if node.is_a?(DefNode)
          str += "function #{node.name} (#{args_names_string(node.arg_names)}) { return #{body_string(node.body)} }"
        end
    end
    str
  end

  def body_string(body)
    if body.is_a?(FunctionCall)
      body.name.value + '(' + args_expression_string(body.arg_expressions) + ')' if body.name
    else
      body.value
    end
  end

  def args_names_string(arg_names)
    return '' if !arg_names
    return '' if arg_names.empty?
    str = ''
    arg_names.each_with_index do |arg_name, index|
      str += arg_name if index == 0
      str += ", #{arg_name}" if index > 0
    end
    str
  end

  def args_expression_string(arg_expressions)
    return '' if !arg_expressions
    return '' if arg_expressions.empty?
    str = ''
    arg_expressions.each_with_index do |arg_expression, index|
      str += arg_expression.value if index == 0
      str += ", #{arg_expression.value}" if index > 0
    end
    str
  end
end


tokens = Tokenizer.new(File.read("test.src")).tokenize
#puts tokens.map(&:inspect).join("\n")

tree = Parser.new(tokens).parse
#puts tree
generated =  Generator.new.generate(tree)

RUNTIME = "function add(x, y) { return x + y };"
TEST = "console.log(newFunction(17))"
puts [RUNTIME, generated, TEST].join("\n")

