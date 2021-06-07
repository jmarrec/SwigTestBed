# C++ SWIG: Test bed

A repo for testing stuff with swig.


### Getting setup for the MCVE

This assumes you have SWIG, Python and Ruby available in your path (Note: Tested with SWIG 4.0.2, Python 3.9 and Ruby 2.7.2).

In the root of the directory:

```
mkdir build
cd build
cmake -G Ninja ../
ninja
```

Some tests are available in `CTest`, so you can run the entire test suite via `ninja test` or `ctest` (`ctest -C Release` on Windows)
