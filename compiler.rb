#!/usr/bin ruby

class Tokenizer
  TOKEN_TYPES = [
    [:def, /\bdef\b/],
    [:end, /\bend\b/],
    [:identifier, /\b[a-zA-Z]+\b/],
    [:integer, /\b[0-9]+\b/],
    [:var_name, /\b[a-zA-Z]+\b/],
    [:open_paren, /\(/],
    [:close_paren, /\)/]
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
    consume(:def)
    identifier = consume(:identifier)
    consume(:open_paren) 
    consume(:close_paren)
    return_value = consume_body
    consume(:end)
    DefNode.new(identifier.value, return_value.value)
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

DefNode = Struct.new(:name, :return_value)

class Generator
  def generate(node)
    "function #{node.name} () { return #{node.return_value} }"
  end
end


tokens = Tokenizer.new(File.read("test.src")).tokenize
#puts tokens.map(&:inspect).join("\n")

tree = Parser.new(tokens).parse
#puts tree
puts Generator.new.generate(tree)