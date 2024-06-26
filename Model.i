#ifndef MODEL_I
#define MODEL_I


#ifdef SWIGRUBY
%ensure_fragment(SWIGFromCharPtrAndSize)
// Override to force utf8 encoding via rb_utf8_str_new instead of rb_str_new: TODO: this is ignored by swig actually
%fragment("SWIG_FromCharPtrAndSize","header",fragment="SWIG_pchar_descriptor") {
SWIGINTERNINLINE VALUE
SWIG_FromCharPtrAndSize(const char* carray, size_t size)
{
  if (carray) {
    if (size > LONG_MAX) {
      swig_type_info* pchar_descriptor = SWIG_pchar_descriptor();
      return pchar_descriptor ? SWIG_NewPointerObj(%const_cast(carray,char *), pchar_descriptor, 0) : Qnil;
    } else {
      return rb_utf8_str_new(carray, %numeric_cast(size,long));
    }
  } else {
    return Qnil;
  }
}
}
#endif

%begin %{
  // ... code in begin section ...
%}

%runtime %{
  // ... code in runtime section ...
%}

%header %{
  // ... code in header section ...
%}

%wrapper %{
  // ... code in wrapper section ...
%}

%init %{
  // ... code in init section ...
%}

%module mylib

%include <std_string.i>


%{
  #include <Model.hpp>
  #include <json/json.h>
// #if defined SWIGRUBY
//   #include <functional>
// #endif
  #include <type_traits>
%}

#if defined SWIGPYTHON

%fragment("SWIG_std_filesystem", "header") {
  SWIGINTERN PyObject *SWIG_std_filesystem_importPathClass() {
    PyObject *module = PyImport_ImportModule("pathlib");
    PyObject *cls = PyObject_GetAttrString(module, "Path");
    Py_DECREF(module);
    return cls;
  }

  SWIGINTERN bool SWIG_std_filesystem_isPathInstance(PyObject *obj) {
    PyObject *cls = SWIG_std_filesystem_importPathClass();
    bool is_instance = PyObject_IsInstance(obj, cls);
    Py_DECREF(cls);
    return is_instance;
  }

  SWIGINTERN std::filesystem::path SWIG_std_filesystem_python_to_cpp(PyObject *obj) {
    PyObject *str_obj = PyObject_Str(obj);
    std::filesystem::path result;
    if constexpr (std::is_same_v<typename std::filesystem::path::value_type, wchar_t>) {
      Py_ssize_t size = 0;
      wchar_t *ws = PyUnicode_AsWideCharString(str_obj, &size);
      result = std::filesystem::path(std::wstring(ws, static_cast<size_t>(size)));
      PyMem_Free(ws);
    } else {
      const char *s = PyUnicode_AsUTF8(str_obj);
      result = std::filesystem::path(s);
    }
    Py_DECREF(str_obj);
    return result;
  }

  SWIGINTERN PyObject * SWIG_std_filesystem_python_to_cpp(const std::filesystem::path& p) {
    PyObject *args;
    if constexpr (std::is_same_v<typename std::filesystem::path::value_type, wchar_t>) {
      std::wstring s = p.generic_wstring();
      args = Py_BuildValue("(u)", s.data());
    } else {
      std::string s = p.generic_string();
      args = Py_BuildValue("(s)", s.data());
    }
    PyObject *cls = SWIG_std_filesystem_importPathClass();
    PyObject * result = PyObject_CallObject(cls, args);
    Py_DECREF(cls);
    Py_DECREF(args);
    return result;
  }
}

%fragment("JsonToDict","header", fragment="SWIG_FromCharPtrAndSize") {
  SWIGINTERN PyObject* SWIG_From_JsonValue(const Json::Value& value) {
    PyErr_WarnEx(PyExc_UserWarning, "Translating a Json::Value to a PyObject", 1);  // Debugging

    if (value.isNull()) {
      return Py_None;
    }

    if (value.isBool()) {
      return value.asBool() ? Py_True : Py_False;
    }

    if (value.isIntegral()) {
      return PyLong_FromLongLong(value.asInt64());
    }

    if (value.isNumeric()) {
       return PyFloat_FromDouble(value.asDouble());
    }

    if (value.isString()) {
      // return PyUnicode_FromString(value.asCString());
      const auto str = value.asString();
      return SWIG_FromCharPtrAndSize(str.data(), str.size());
    }

    if (value.isArray()) {
      PyObject* result = PyList_New(value.size());
      Py_ssize_t idx = 0;
      for( const auto& arrayElement : value) {
        // recursive call
        auto val = SWIG_From_JsonValue(arrayElement);
        // PyList_Append(result, val);
        PyList_SetItem(result, idx++, val);
      }
      return result;
    }

    if (value.isObject()) {
      PyObject* result = PyDict_New();
      for( const auto& id : value.getMemberNames()) {
        // recursive call
        auto val = SWIG_From_JsonValue(value[id]);
        PyDict_SetItemString(result, id.c_str(), val);
        Py_DECREF(val);
      }
      return result;
    }

    return Py_None;
  }
}

%typemap(out, fragment="JsonToDict") Json::Value {
  $result = SWIG_From_JsonValue($1);
}

%fragment("ToJsonValue", "header") {
  SWIGINTERN Json::Value SWIG_to_JsonValue(PyObject * obj) {
    PyErr_WarnEx(PyExc_UserWarning, "Constructing a Json::Value", 1);  // Debugging
    if (obj == Py_None) {
      return Json::Value{Json::nullValue};
    }

    if (PyBool_Check(obj)) {
      bool b = PyObject_IsTrue(obj) == 1;
      return Json::Value{b};
    }

    if (PyFloat_Check(obj)) {
      auto d = PyFloat_AsDouble(obj);
      return Json::Value{d};
    }

    if (PyNumber_Check(obj)) { // or PyLong_Check
      std::int64_t i = PyLong_AsLongLong(obj);
      return Json::Value{i};
    }

    if (PyUnicode_Check(obj)) {
      const char *p = PyUnicode_AsUTF8(obj);
      return Json::Value{p};
    }

    if (PyList_Check(obj)) {
      auto result = Json::Value(Json::arrayValue);
      size_t n = PyList_Size(obj);
      for (size_t i = 0; i < n; ++i) {
        result.append(SWIG_to_JsonValue(PyList_GetItem(obj, i)));
      }
      return result;
    }

    if (PyTuple_Check(obj)) {
      auto result = Json::Value(Json::arrayValue);
      size_t n = PyTuple_Size(obj);
      for (size_t i = 0; i < n; ++i) {
        result.append(SWIG_to_JsonValue(PyTuple_GetItem(obj, i)));
      }
      return result;
    }

    if (PyAnySet_Check(obj)) {
      auto result = Json::Value(Json::arrayValue);
      PyObject *iter;
      if ((iter = PyObject_GetIter(obj)) == nullptr) {
        return result;
      }
      PyObject *item;
      while ((item = PyIter_Next(iter)) != nullptr) {
        result.append(SWIG_to_JsonValue(item));
        Py_DECREF(item);
      }
      Py_DECREF(iter);
      return result;
    }

    if (PyDict_Check(obj)) {
      auto result = Json::Value(Json::objectValue);
      PyObject *key;
      PyObject *value;
      Py_ssize_t pos = 0;

      while (PyDict_Next(obj, &pos, &key, &value)) {
        if (!PyUnicode_Check(key)) {
          std::invalid_argument("Object keys must be strings");
        }
        const char * jsonKey = PyUnicode_AsUTF8(key);
        result[jsonKey] = SWIG_to_JsonValue(value);
      }
      return result;
    }

    return Json::Value{Json::nullValue};
  }

}

%typemap(in, fragment="ToJsonValue") Json::Value {
  void* argp = 0;
  int res = SWIG_ConvertPtr($input, &argp, $descriptor(Json::Value *), $disown |  0 );
  if (SWIG_IsOK(res)) {
    PyErr_WarnEx(PyExc_UserWarning, "reusing a Json::Value", 1);
    Json::Value * temp = %reinterpret_cast(argp, $ltype *);
    $1 = *temp;
  } else {
    $1 = SWIG_to_JsonValue($input);
  }
}

%typemap(in, fragment="ToJsonValue") Json::Value const *, Json::Value const & {
  void* argp = 0;
  int res = SWIG_ConvertPtr($input, &argp, $descriptor, $disown |  0 );
  if (SWIG_IsOK(res)) {
    PyErr_WarnEx(PyExc_UserWarning, "reusing a Json::Value", 1);
    $1 = %reinterpret_cast(argp, $ltype);
  } else {
    $1 = new Json::Value(SWIG_to_JsonValue($input));
  }
}


%fragment("ToOSArgumentVariant", "header", fragment="SWIG_std_filesystem") {
  SWIGINTERN Test::OSArgumentVariant SWIG_to_OSArgumentVariant(PyObject * obj) {
    PyErr_WarnEx(PyExc_UserWarning, "Constructing a OSArgumentVariant", 1);  // Debugging
    if (obj == Py_None) {
      return Test::OSArgumentVariant{};
    }

    if (PyBool_Check(obj)) {
      bool b = PyObject_IsTrue(obj) == 1;
      return Test::OSArgumentVariant{b};
    }

    if (PyFloat_Check(obj)) {
      auto d = PyFloat_AsDouble(obj);
      return Test::OSArgumentVariant{d};
    }

    if (PyNumber_Check(obj)) { // or PyLong_Check
      std::int64_t i = PyLong_AsLongLong(obj);
      return Test::OSArgumentVariant{static_cast<int>(i)};
    }

    if (SWIG_std_filesystem_isPathInstance(obj)) {
      PyErr_WarnEx(PyExc_UserWarning, "Constructing a OSArgumentVariant as Path", 1);  // Debugging
      return Test::OSArgumentVariant{SWIG_std_filesystem_python_to_cpp(obj)};
    }

    if (PyUnicode_Check(obj)) {
      const char *p = PyUnicode_AsUTF8(obj);
      return Test::OSArgumentVariant{std::string{p}};
    }

    throw std::invalid_argument("OSArgumentVariant must be one of None, bool, int, Float, or pathlib.Path");
  }

}


%typemap(in, fragment="ToOSArgumentVariant") std::variant<std::monostate, bool, double, int, std::string, std::filesystem::path> {
  void* argp = 0;
  int res = SWIG_ConvertPtr($input, &argp, $descriptor(Test::OSArgumentVariant *), $disown |  0 );
  if (SWIG_IsOK(res)) {
    PyErr_WarnEx(PyExc_UserWarning, "reusing a OSArgumentVariant", 1);
    Json::Value * temp = %reinterpret_cast(argp, $ltype *);
    $1 = *temp;
  } else {
    $1 = SWIG_to_OSArgumentVariant($input);
  }
}

%typemap(in, fragment="ToOSArgumentVariant") std::variant<std::monostate, bool, double, int, std::string, std::filesystem::path> const *, std::variant<std::monostate, bool, double, int, std::string, std::filesystem::path> const & {
  void* argp = 0;
  int res = SWIG_ConvertPtr($input, &argp, $descriptor, $disown |  0 );
  if (SWIG_IsOK(res)) {
    PyErr_WarnEx(PyExc_UserWarning, "reusing a OSArgumentVariant", 1);
    $1 = %reinterpret_cast(argp, $ltype);
  } else {
    $1 = new Test::OSArgumentVariant(SWIG_to_OSArgumentVariant($input));
  }
}

%typemap(out, fragment="SWIG_std_filesystem", fragment="SWIG_FromCharPtrAndSize") std::variant<std::monostate, bool, double, int, std::string, std::filesystem::path> {
  $result = std::visit(
    [](auto&& arg) -> PyObject* {
      using T = std::decay_t<decltype(arg)>;
      if constexpr (std::is_same_v<T, std::monostate>) {
        return Py_None;
      } else if constexpr (std::is_same_v<T, bool>) {
        return arg ? Py_True : Py_False;
      } else if constexpr (std::is_same_v<T, double>) {
        return PyFloat_FromDouble(arg);
      } else if constexpr (std::is_same_v<T, int>) {
        return PyLong_FromLongLong(arg);
      } else if constexpr (std::is_same_v<T, std::string>) {
        return SWIG_FromCharPtrAndSize(arg.data(), arg.size());;
      } else if constexpr (std::is_same_v<T, std::filesystem::path>) {
        return SWIG_std_filesystem_python_to_cpp(arg);
      }
    },
    $1);

}

#endif

#if defined SWIGRUBY

%fragment("JsonToDict","header", fragment="SWIG_FromCharPtrAndSize") {
  SWIGINTERN VALUE SWIG_From_JsonValue(const Json::Value& value) {

    if (value.isNull()) {
      return Qnil;
    }

    if (value.isBool()) {
      return value.asBool() ? Qtrue : Qfalse;
    }

    if (value.isIntegral()) {
      return INT2NUM(value.asInt64());
    }

    if (value.isNumeric()) {
     return DOUBLE2NUM(value.asDouble());
    }

    if (value.isString()) {
      const auto str = value.asString();
      return SWIG_FromCharPtrAndSize(str.data(), str.size());
    }

    if (value.isArray()) {
      VALUE result = rb_ary_new2(value.size());
      for( const auto& arrayElement : value) {
        rb_ary_push(result, SWIG_From_JsonValue(arrayElement));
      }
      return result;
    }

    if (value.isObject()) {
      VALUE result = rb_hash_new();
      for( const auto& id : value.getMemberNames()) {
        rb_hash_aset(result, ID2SYM(rb_intern(id.data())), SWIG_From_JsonValue(value[id]));
      }
      return result;
    }

    return rb_hash_new();
  }
}

%typemap(out, fragment="JsonToDict") Json::Value {
  $result = SWIG_From_JsonValue($1);
}

%fragment("ToJsonValue","header") {

  SWIGINTERN Json::Value SWIG_to_JsonValue(VALUE obj) {

    if (RB_TYPE_P(obj, T_NIL)) {
      return Json::Value{Json::nullValue};
    }

    if (RB_TYPE_P(obj, T_TRUE)) {
      return Json::Value(true);
    }

    if (RB_TYPE_P(obj, T_FALSE)) {
      return Json::Value(false);
    }

    if (RB_TYPE_P(obj, T_FIXNUM)) {
      return Json::Value(NUM2INT(obj));
    }

    if (RB_TYPE_P(obj, T_BIGNUM)) {
      return Json::Value(static_cast<std::int64_t>(NUM2LL(obj)));
    }

    if (RB_TYPE_P(obj, T_FLOAT)) {
      return Json::Value(NUM2DBL(obj));
    }

    if (RB_TYPE_P(obj, T_SYMBOL)) {
      return Json::Value(rb_id2name(SYM2ID(obj)));
    }

    if (RB_TYPE_P(obj, T_STRING)) {
      // This is potentially not null terminated...
      return Json::Value(StringValuePtr(obj));
    }

    if (RB_TYPE_P(obj, T_ARRAY)) {
      auto result = Json::Value(Json::arrayValue);

      VALUE* elements = RARRAY_PTR(obj);
      for (long c = 0; c < RARRAY_LEN(obj); ++c) {
        VALUE entry = elements[c];
        result.append(SWIG_to_JsonValue(entry));
      }
      return result;
    }


    if (RB_TYPE_P(obj, T_HASH)) {
      auto result = Json::Value(Json::objectValue);

      // rb_foreach_func’ has initializer but incomplete type
      // std::function<int (*)(VALUE, VALUE, VALUE)> rb_foreach_func = [&result](VALUE key, VALUE value, VALUE /* arg */) -> int {
      //   std::string jsonKey;
      //   Json::Value jsonValue;
      //   if (RB_TYPE_P(key, T_SYMBOL)) {
      //     jsonKey = std::string(rb_id2name(SYM2ID(key)));
      //   } else if (RB_TYPE_P(key, T_STRING)) {
      //     // This is potentially not null terminated...
      //     jsonKey = std::string(StringValuePtr(key));
      //   } else {
      //     throw std::runtime_error("Object keys must be strings or keys");
      //   }
      //   result[jsonKey] = SWIG_to_JsonValue(value);
      //   return ST_CONTINUE;
      // };
      // rb_hash_foreach(obj, rb_foreach_func, 0);
      VALUE keys = rb_funcall(obj, rb_intern("keys"), 0);
      VALUE* elements = RARRAY_PTR(keys);
      for (long c = 0; c < RARRAY_LEN(keys); ++c) {
        VALUE key = elements[c];
        std::string jsonKey;
        if (RB_TYPE_P(key, T_SYMBOL)) {
           jsonKey = std::string(rb_id2name(SYM2ID(key)));
        } else if (RB_TYPE_P(key, T_STRING)) {
          // This is potentially not null terminated...
          jsonKey = std::string(StringValuePtr(key));
        } else {
          throw std::runtime_error("Object keys must be strings or keys");
        }
        VALUE value = rb_hash_aref(obj, key);
        result[jsonKey] = SWIG_to_JsonValue(value);
      }
      return result;
    }

    return Json::Value{Json::nullValue};
  }
}

%typemap(in, fragment="ToJsonValue") Json::Value {
  void* argp = 0;
  int res = SWIG_ConvertPtr($input, &argp, $descriptor(Json::Value *), $disown |  0 );
  if (SWIG_IsOK(res)) {
    Json::Value * temp = %reinterpret_cast(argp, $ltype *);
    $1 = *temp;
  } else {
    $1 = SWIG_to_JsonValue($input);
  }
}

%typemap(in, fragment="ToJsonValue") Json::Value const *, Json::Value const & {
  void* argp = 0;
  int res = SWIG_ConvertPtr($input, &argp, $descriptor, $disown |  0 );
  if (SWIG_IsOK(res)) {
    $1 = %reinterpret_cast(argp, $ltype);
  } else {
    $1 = new Json::Value(SWIG_to_JsonValue($input));
  }
}

#endif

%include <Model.hpp>

#endif //MODEL_I

