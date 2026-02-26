#include <stdio.h>
#include <stdlib.h>

#include "aivm_parity.h"

static int read_file(const char* path, char* buffer, size_t capacity)
{
    FILE* file;
    size_t read_count;

    file = fopen(path, "rb");
    if (file == NULL) {
        return 0;
    }

    read_count = fread(buffer, 1U, capacity - 1U, file);
    if (ferror(file) != 0) {
        fclose(file);
        return 0;
    }

    buffer[read_count] = '\0';
    fclose(file);
    return 1;
}

int main(int argc, char** argv)
{
    char left[65536];
    char right[65536];

    if (argc != 3) {
        fprintf(stderr, "usage: aivm_parity_cli <left> <right>\n");
        return 2;
    }

    if (!read_file(argv[1], left, sizeof(left))) {
        fprintf(stderr, "failed to read left input\n");
        return 2;
    }

    if (!read_file(argv[2], right, sizeof(right))) {
        fprintf(stderr, "failed to read right input\n");
        return 2;
    }

    if (aivm_parity_equal_normalized(left, right)) {
        printf("PARITY_OK\n");
        return 0;
    }

    printf("PARITY_DIFF\n");
    return 1;
}
