ruby_lib_path = File.expand_path(File.join(__dir__, '../build/Products/ruby/mylib.so'))

if !File.exist?(ruby_lib_path)
  puts "Error, this assumes you already built the project in <root>/build"
  exit 1
end

EXPECTED_JSON = File.expand_path(File.join(__dir__, '../tests/expected.json'))


require ruby_lib_path
require 'json'

require 'minitest/autorun'

class Encoding_Test < Minitest::Test

  # def test_encoding
  #   test_string = "模型"
  #   assert_equal(Encoding::UTF_8, test_string.encoding)

  #   p = Mylib::Model.new(test_string)
  #   name_string = p.getName()
  #   assert_equal(Encoding::UTF_8, name_string.encoding)
  # end

  # def test_encoding_explicit
  #   Encoding::default_external = Encoding::UTF_8
  #   Encoding::default_internal = Encoding::UTF_8

  #   test_string = "模型"
  #   assert_equal(Encoding::UTF_8, test_string.encoding)

  #   p = Mylib::Model.new(test_string)
  #   name_string = p.getName()
  #   assert_equal(Encoding::UTF_8, name_string.encoding)
  # end

  def test_json
    expected = JSON.parse(File.read(EXPECTED_JSON), symbolize_names: true)
    m = Mylib::Model.new("John")
    d = m.toJSON()
    assert_equal(expected, d)
  end

end
