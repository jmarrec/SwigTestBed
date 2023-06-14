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
%}

#if defined SWIGPYTHON
%fragment("JsonToDict","header", fragment="SWIG_FromCharPtrAndSize") {
  PyObject* SWIG_From_JsonValue(const Json::Value& value) {

      if (value.isBool()) {
        return value.asBool() ? Py_True : Py_False;
      } else if (value.isIntegral()) {
          return PyLong_FromLongLong(value.asInt64());
      } else if (value.isNumeric()) {
         return PyFloat_FromDouble(value.asDouble());
      } else if (value.isString()) {
         // return PyUnicode_FromString(value.asCString());
         const auto str = value.asString();
         return SWIG_FromCharPtrAndSize(str.data(), str.size());
      } else if (value.isArray()) {
          PyObject* result = PyList_New(value.size());
          Py_ssize_t idx = 0;
          for( const auto& arrayElement : value) {
              // TODO: this should do a recursive call to convert n (which is Json::Value) to a python type...
              auto val = SWIG_From_JsonValue(arrayElement);
              // PyList_Append(result, val);
              PyList_SetItem(result, idx++, val);
          }
          return result;

      } else if (value.isObject()) {
          PyObject* result = PyDict_New();
          for( const auto& id : value.getMemberNames()) {
              // TODO: this should do a recursive call to convert *$1[id] (which is a Json::Value) to a python type...
              auto val = SWIG_From_JsonValue(value[id]);
              PyDict_SetItemString(result, id.c_str(), val);
              Py_DECREF(val);
          }
          return result;
      }

      return PyDict_New();
  }
}
%typemap(out, fragment="JsonToDict") Json::Value {
  $result = SWIG_From_JsonValue($1);
}
#endif

#if defined SWIGRUBY
%fragment("JsonToDict","header", fragment="SWIG_FromCharPtrAndSize") {
  VALUE SWIG_From_JsonValue(const Json::Value& value) {

      if (value.isBool()) {
        return value.asBool() ? Qtrue : Qfalse;
      } else if (value.isIntegral()) {
          return INT2NUM(value.asInt64());
      } else if (value.isNumeric()) {
         return DOUBLE2NUM(value.asDouble());
      } else if (value.isString()) {
         const auto str = value.asString();
         return SWIG_FromCharPtrAndSize(str.data(), str.size());
      } else if (value.isArray()) {
          VALUE result = rb_ary_new2(value.size());
          for( const auto& arrayElement : value) {
              rb_ary_push(result, SWIG_From_JsonValue(arrayElement));
          }
          return result;

      } else if (value.isObject()) {
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
#endif

%include <Model.hpp>

#endif //MODEL_I

