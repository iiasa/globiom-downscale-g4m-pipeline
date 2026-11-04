#include "IntToStr.h"

std::string IntToStr(int i)
 {
  std::string res;
  bool minus = false;
  if (i == 0) {
    res = "0";
  } else {
    if (i < 0) {
      minus = true;
      i *= -1;
    }
    while (i!=0) {
      char t = i % 10;
      res += char(int('1') - 1 + t);
      i = (i - t)/10;
    }
  }
  char c;
  char len = res.length();
  for (int ii = 0; ii <= (len-ii-1); ii++)
   {
    c = res[ii];
    res[ii] = res[len-1-ii];
    res[len-1-ii] = c;
   }
  if (minus) res = std::string("-") + res;
  return res;
 }
