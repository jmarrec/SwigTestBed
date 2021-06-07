#include "Model.hpp"
#include <string>

namespace Test {
  Model::Model(std::string name) : name_(std::move(name)) {}

  const std::string& Model::getName() const {
    return name_;
  }

  bool Model::setName(const std::string& name) {
    name_ = name;
    return true;
  }
}  // namespace Test
