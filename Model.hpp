#ifndef MODEL_HPP
#define MODEL_HPP

#include <string>
#include <filesystem>

namespace Json {
class Value;
}

namespace Test {
class Model
{
 public:
  explicit Model(std::string name);
  static Model fromJSON(Json::Value value);

  const std::string& getName() const;
  bool setName(const std::string& name);
  Json::Value toJSON() const;

  bool setPath(std::filesystem::path p);
  std::filesystem::path getPath() const;

 private:
  std::string name_;
  std::filesystem::path path_;
};
}  // namespace Test

#endif
