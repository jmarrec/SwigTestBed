#ifndef MODEL_HPP
#define MODEL_HPP

#include <string>

namespace Test {
  class Model
  {
    public:
      explicit Model(std::string name);
      const std::string& getName() const;
      bool setName(const std::string& name);

    private:
      std::string name_;

  };
}  // namespace Test

#endif
