//+ignore
package dayX

import "core:fmt"
import "core:math"
import "core:mem"
import "core:os2"
import "core:io"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

stderr: io.Stream

main :: proc() {
    stderr := os2.to_writer(os2.stderr)

    fmt.println("Advent of Code Day X!")
    fmt.println("=====================")

    if len(os2.args) < 2 {
        fmt.wprintln(stderr, "Error - no file provided")
        usage()
        os2.exit(1)
    }

    data, file_err := os2.read_entire_file_from_path(os.args[1], context.allocator)
    if file_err != nil {
        fmt.fprintfln(os.stderr, "Error reading %s - %#v", os.args[1], file_err)
        usage()
        os2.exit(1)
    }

    p1 := part_1(string(data))
    p2 := part_2(string(data))

    fmt.println("Part 1:", p1)
    fmt.println("Part 2:", p2)
}

usage :: proc() {
    fmt.fprintln(os.stderr, "Usage: dayN path/to/input.txt")
}

part_1 :: proc(data: string) -> int {
    return 0
}

part_2 :: proc(data: string) -> int {
    return 0
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 1234)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 1234)
}

test_input := ``