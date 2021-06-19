# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "Elemental"
version = v"1.5.1"

# Collection of sources required to build Elemental
sources = [
    GitSource("https://github.com/llnl/Elemental",
              "85a74ed25461bd8d8c638105663b6ea663451db8"),
]

# Bash recipe for building across all platforms
script = raw"""
if [[ "$nbits" == "64" ]]; then
  INT64="ON"
else
  INT64="OFF"
fi

if [[ "$nbits" == "64" ]] && [[ "$target" != aarch64-* ]]; then
  BLAS_LAPACK_LIB="$libdir/libopenblas64_.$dlext"
  BLAS_LAPACK_SUFFIX="_64_"
  BLAS_INT64="ON"
else
  BLAS_LAPACK_LIB="$libdir/libopenblas.$dlext"
  BLAS_LAPACK_SUFFIX=""
  BLAS_INT64="OFF"
fi

cd ${WORKSPACE}/srcdir/Elemental
mkdir -p build && cd build

cmake \
  -DCMAKE_INSTALL_PREFIX="${prefix}" \
  -DCMAKE_TOOLCHAIN_FILE="$CMAKE_TARGET_TOOLCHAIN" \
  -DCMAKE_BUILD_TYPE="Release" \
  -DEL_USE_64BIT_INTS="$INT64" \
  -DEL_USE_64BIT_BLAS_INTS="$BLAS_INT64" \
  -DEL_DISABLE_PARMETIS="ON" \
  -DMETIS_TEST_RUNS_EXITCODE="0" \
  -DMETIS_TEST_RUNS_EXITCODE__TRYRUN_OUTPUT="" \
  -DMATH_LIBS="$BLAS_LAPACK_LIB" \
  -DBLAS_LIBRARIES="$BLAS_LAPACK_LIB" \
  -DLAPACK_LIBRARIES="$BLAS_LAPACK_LIB" \
  -DEL_BLAS_SUFFIX="$BLAS_LAPACK_SUFFIX" \
  -DEL_LAPACK_SUFFIX="$BLAS_LAPACK_SUFFIX" \
  ..

make "-j$nproc"
make install
"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = supported_platforms(; experimental=true)
platforms = expand_cxxstring_abis(platforms)
filter!(!Sys.iswindows, platforms)

# The products that we will ensure are always built
products = [
    LibraryProduct("libEl", :libEl),
    LibraryProduct("libElSuiteSparse", :libElSuiteSparse),
]

# Dependencies that must be installed before this package can be built
dependencies = [
    Dependency("METIS_jll"),
    Dependency("MPICH_jll"),
    Dependency("OpenBLAS_jll"),
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies; julia_compat="1.6", preferred_gcc_version = v"8")
