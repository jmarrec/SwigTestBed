#ifndef MODEL_HPP
#define MODEL_HPP

#include <filesystem>
#include <map>
#include <string>
#include <variant>

namespace Json {
class Value;
}

namespace Test {

using OSArgumentVariant = std::variant<std::monostate, bool, double, int, std::string, std::filesystem::path>;

class Model
{
 public:
  explicit Model(std::string name);
  static Model fromJSON(Json::Value value);
  static Json::Value roundTrip(Json::Value value);
  static Json::Value roundTripRef(const Json::Value& value);
  static const Json::Value& makeJSONConstRef();

  const std::string& getName() const;
  bool setName(const std::string& name);
  Json::Value toJSON() const;

  bool setPath(std::filesystem::path p);
  std::filesystem::path getPath() const;

  OSArgumentVariant variantValue() const;
  bool setVariantValue(const OSArgumentVariant& argVar);
  Json::Value variantValueAsJSON() const;

 private:
  std::string name_;
  std::filesystem::path path_;
  OSArgumentVariant m_variant;
};

Json::Value argumentVariantToJSONValue(const OSArgumentVariant& argVar);
std::string printOSArgumentVariant(const OSArgumentVariant& argVar);

void consumeArgumentMap(const std::map<std::string, OSArgumentVariant>& user_arguments);

// Testing returning a map
std::map<std::string, OSArgumentVariant> getMap();

std::filesystem::path toPath(const std::string& s);

}  // namespace Test

#endif
