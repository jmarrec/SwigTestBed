#ifndef MODEL_HPP
#define MODEL_HPP

#include <string>

namespace Json {
class Value;
}

namespace Test {
class Model
{
 public:
  explicit Model(std::string name);
  const std::string& getName() const;
  bool setName(const std::string& name);
  Json::Value toJSON() const;

 private:
  std::string name_;
};
}  // namespace Test

#endif
