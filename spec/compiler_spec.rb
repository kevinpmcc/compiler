require_relative '../compiler'

describe 'our little compiler' do
  it 'deals with assigning a variable and then declaring a function' do
    code = "x = 7\ndef h(x,y)\n  x\nend"

    tokens = Tokenizer.new(code).tokenize
    tree = Parser.new(tokens).parse
    generated =  Generator.new.generate(tree)

    expect(generated).to eq('var x = 7;function h (x, y) { return x }')
  end

  it 'deals with just assigning a variable' do
    code = "x = 7"

    tokens = Tokenizer.new(code).tokenize
    tree = Parser.new(tokens).parse
    generated =  Generator.new.generate(tree)

    expect(generated).to eq('var x = 7;')
  end

  it 'deals with just declaring a function' do
    code = "def lovelyFunction(a,b,c,d,e,f)\n a\n end"
    tokens = Tokenizer.new(code).tokenize
    tree = Parser.new(tokens).parse
    generated =  Generator.new.generate(tree) 
    expect(generated).to eq('function lovelyFunction (a, b, c, d, e, f) { return a }')
  end

  it 'can call a function from within a function' do
    code = "def lovelyFunction(a,b)\n add(a,b)\n end"

    tokens = Tokenizer.new(code).tokenize
    tree = Parser.new(tokens).parse
    generated =  Generator.new.generate(tree)  

    expect(generated).to eq('function lovelyFunction (a, b) { return add(a, b) }')
  end

  it 'can call a function' do
    code = "add(a,b)"

    tokens = Tokenizer.new(code).tokenize
    tree = Parser.new(tokens).parse
    generated =  Generator.new.generate(tree)  

    expect(generated).to eq('add(a, b)')
  end
end