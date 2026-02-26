#include <dirent.h>
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

static int recursive_clean(int dirfd, const char *dirname) {
	struct stat sb;
	DIR *dir;
	struct dirent *dirent;
	int fd;

	if (fstatat(dirfd, dirname, &sb, AT_SYMLINK_NOFOLLOW) < 0)
		return errno != ENOTDIR && errno != ENOENT ? -1 : 0;

	if (!S_ISDIR(sb.st_mode))
		return unlinkat(dirfd, dirname, 0);

	if ((sb.st_mode & S_IRWXU) != S_IRWXU)
		fchmodat(dirfd, dirname, S_IRWXU, AT_SYMLINK_NOFOLLOW);

	fd = openat(dirfd, dirname, O_RDONLY|O_DIRECTORY|O_NOFOLLOW);
	if (fd < 0)
		return -1;
	dir = fdopendir(fd);
	if (dir == NULL) {
		close(fd);
		return -1;
	}

	while ((dirent = readdir(dir)) != NULL) {
		if (dirent->d_name[0] == '.' && (dirent->d_name[1] == '\0' || (dirent->d_name[1] == '.' && dirent->d_name[2] == '\0')))
			continue;

		if (recursive_clean(fd, dirent->d_name) < 0)
			break;
	}
	closedir(dir);

	return unlinkat(dirfd, dirname, AT_REMOVEDIR);
}

int main(int argc, char **argv) {
	if (argc != 3 || strcmp(argv[1], "-rf")) {
		fprintf(stderr, "Usage: abuild-rm -rf <path>\n");
		return 1;
	}

	return recursive_clean(AT_FDCWD, argv[2]) == -1 ? 1 : 0;
}
