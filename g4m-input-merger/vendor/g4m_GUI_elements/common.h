#ifndef COMMON_H_
#define COMMON_H_

#ifndef PATHSEPARATOR_
#define PATHSEPARATOR_

#include <string>

#ifdef unix
static std::string pathSeparator = "/";
#else
static std::string pathSeparator = "\\";
#endif

#endif // #define PATHSEPARATOR_

#endif // #define COMMON_H_
