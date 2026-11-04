#include "endianness.h"

template <class T>
void INV_BYTE_ORDER(T &v)
{
    char typeSize = sizeof(T);
    char *tmp = new char[typeSize];
    memcpy(tmp, &v, typeSize);
    for (int i = 0; i < typeSize/2; i++)
    {
        char tmpByte = tmp[typeSize - i - 1];
        tmp[typeSize - i - 1] = tmp[i];
        tmp[i] = tmpByte;
    }
    memcpy(&v, tmp, typeSize);
	delete [] tmp;
}

template void INV_BYTE_ORDER<int>(int &v);
template void INV_BYTE_ORDER<long long>(long long &v);
template void INV_BYTE_ORDER<float>(float &v);
template void INV_BYTE_ORDER<double>(double &v);