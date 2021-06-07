ruby_lib_path = File.expand_path(File.join(__dir__, '../build/Products/ruby/mylib.so'))

if !File.exist?(ruby_lib_path)
  puts "Error, this assumes you already built the project in <root>/build"
  exit 1
end

require ruby_lib_path

require 'minitest/autorun'

class Encoding_Test < Minitest::Test

  def test_encoding
    test_string = "模型"
    assert_equal("UTF-8", test_string.encoding.to_s)

    p = Mylib::Model.new(test_string)
    name_string = p.getName()
    assert_equal("UTF-8", name_string.encoding.to_s)
  end
end
