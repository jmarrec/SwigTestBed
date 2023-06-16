#include "Model.hpp"
#include <stdexcept>
#include <string>
#include <json/json.h>

namespace Test {
Model::Model(std::string name) : name_(std::move(name)) {}

Model Model::fromJSON(Json::Value value) {

  if (!value.isMember("name") && value["name"].isString()) {
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

}  // namespace Test
