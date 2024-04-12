#include "Model.hpp"
#include <stdexcept>
#include <string>
#include <json/json.h>

namespace Test {
Model::Model(std::string name) : name_(std::move(name)) {}

Model Model::fromJSON(Json::Value value) {

  if (!(value.isMember("name") && value["name"].isString())) {
    throw std::runtime_error("the name parameter is required");
  }

  return Model(value["name"].asString());
}

const std::string& Model::getName() const {
  return name_;
}

bool Model::setName(const std::string& name) {
  name_ = name;
  return true;
}

Json::Value Model::toJSON() const {
  Json::Value root;
  root["name"] = name_;
  root["int"] = 1;
  root["bool"] = true;

  auto& arrayValue = root["array"];
  arrayValue.append("value1");
  arrayValue.append("value2");

  root["object"]["name1"] = "A";
  root["object"]["value"] = 10.53;

  auto& complexObject = root["complex"];
  auto& complexArray = complexObject["array"];
  for (const auto& s : {"A", "B"}) {
    Json::Value& attributeElement = complexArray.append(Json::Value(Json::objectValue));
    attributeElement["name"] = s;
    attributeElement["object"]["name1"] = "A";
    attributeElement["object"]["array"].append("sub1");
    attributeElement["object"]["array"].append("sub2");
  }

  return root;
}

bool Model::setPath(std::filesystem::path p) {
  path_ = std::move(p);
  return true;
}

std::filesystem::path Model::getPath() const {
  return path_;
}

Json::Value Model::roundTrip(Json::Value value) {
  return value;
}
Json::Value Model::roundTripRef(const Json::Value& value) {
  return value;
}

const Json::Value& Model::makeJSONConstRef() {
  const static Json::Value root = []() {
    Json::Value root;
    root["name"] = "Static";
    root["int"] = 1;
    root["bool"] = true;

    auto& arrayValue = root["array"];
    arrayValue.append("value1");
    arrayValue.append("value2");

    root["object"]["name1"] = "A";
    root["object"]["value"] = 10.53;

    auto& complexObject = root["complex"];
    auto& complexArray = complexObject["array"];
    for (const auto& s : {"A", "B"}) {
      Json::Value& attributeElement = complexArray.append(Json::Value(Json::objectValue));
      attributeElement["name"] = s;
      attributeElement["object"]["name1"] = "A";
      attributeElement["object"]["array"].append("sub1");
      attributeElement["object"]["array"].append("sub2");
    }

    return root;
  }();
  return root;
}

// helper constant for the visitor below so we static assert we didn't miss a type
template <class>
inline constexpr bool always_false_v = false;

Json::Value argumentVariantToJSONValue(const OSArgumentVariant& argVar) {
  return std::visit(
    [](auto&& arg) -> Json::Value {
      using T = std::decay_t<decltype(arg)>;
      if constexpr (std::is_same_v<T, std::monostate>) {
        return Json::nullValue;
      } else if constexpr (std::is_same_v<T, bool>) {  // NOLINT(bugprone-branch-clone)
        return arg;
      } else if constexpr (std::is_same_v<T, double>) {
        return arg;
      } else if constexpr (std::is_same_v<T, int>) {
        return arg;
      } else if constexpr (std::is_same_v<T, std::string>) {
        return arg;
      } else if constexpr (std::is_same_v<T, std::filesystem::path>) {
        return arg.string();
      } else {
        static_assert(always_false_v<T>, "non-exhaustive visitor!");
      }
    },
    argVar);
}

OSArgumentVariant Model::variantValue() const {
  return m_variant;
}

Json::Value Model::variantValueAsJSON() const {
  return argumentVariantToJSONValue(m_variant);
}

bool Model::setVariantValue(const OSArgumentVariant& argVar) {
  m_variant = argVar;
  return true;
}

}  // namespace Test
