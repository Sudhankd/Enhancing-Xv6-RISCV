#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// #include <stdarg.h>

// #include "user/user.h"
int main()
{
    int res = getreadcount();
    printf("%d\n",res);
    // fprintf(1,res);
    return 0;
}