#include <fcntl.h>
#include <sys/stat.h>
#include "spdos.h"

int isdir(const char *path)
{
	static unsigned char statbuf[256];
	struct stat *st = (struct stat *) statbuf;

	if (stat(path, st) < 0) {
		return 0;
	}
	unsigned short mode = *(unsigned short *) statbuf;
	return (mode & S_IFDIR) != 0;
}
