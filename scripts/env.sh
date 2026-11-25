# Sourced by the other scripts.
#
# Workaround for incomplete Command Line Tools installations, where
# /Library/Developer/CommandLineTools/usr/include/c++/v1 contains only a few
# stray files, so clang++ cannot find <cstddef>. We point clang++ at the
# complete libc++ headers inside the macOS SDK instead. On a healthy setup this
# is harmless (the SDK headers are the same ones clang would use anyway).
if [ "$(uname)" = "Darwin" ]; then
    SDK="$(xcrun --show-sdk-path)"
    if [ -d "$SDK/usr/include/c++/v1" ]; then
        CXX="clang++ -nostdinc++ -isystem $SDK/usr/include/c++/v1"
        export CXX
    fi
fi
