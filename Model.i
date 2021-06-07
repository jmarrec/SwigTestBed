#ifndef MODEL_I
#define MODEL_I


#ifdef SWIGRUBY
%ensure_fragment(SWIGFromCharPtrAndSize)
// Override to force utf8 encoding via rb_utf8_str_new instead of rb_str_new
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
%}

%include <Model.hpp>

#endif //MODEL_I

