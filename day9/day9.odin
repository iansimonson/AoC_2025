package day9

import "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:mem"
import "core:os/os2"
import "core:io"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:testing"
import "core:time"

stderr: io.Stream

main :: proc() {
    stderr = os2.to_writer(os2.stderr)

    fmt.println("Advent of Code Day 9!")
    fmt.println("=====================")

    if len(os2.args) < 2 {
        fmt.wprintln(stderr, "Error - no file provided")
        usage()
        os2.exit(1)
    }

    data, file_err := os2.read_entire_file_from_path(os2.args[1], context.allocator)
    if file_err != nil {
        fmt.wprintfln(stderr, "Error reading %s - %#v", os2.args[1], file_err)
        usage()
        os2.exit(1)
    }

    p1 := part_1(string(data))
    p2 := part_2(string(data))

    fmt.println("Part 1:", p1)
    fmt.println("Part 2:", p2)
}

usage :: proc() {
    fmt.wprintfln(stderr, "Usage: %s path/to/input.txt", os2.args[0])
}

part_1 :: proc(data: string) -> int {
    data := data
    largest: int
    points := make([dynamic][2]int, 0, 100)
    for line in strings.split_lines_iterator(&data) {
        comma := strings.index_byte(line, ',')
        p_x, _ := strconv.parse_int(line[:comma])
        p_y, _ := strconv.parse_int(line[comma+1:])
        point := [2]int{p_x, p_y}
        for p2 in points {
            // inclusive ranges
            d := linalg.abs(p2 - point + [2]int{1, 1})
            area := d.x * d.y
            if area > largest {
                largest = area
            }
        }
        append(&points, point)
    }

    return largest
}

part_2 :: proc(data: string) -> int {
    return 0
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 50)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 1234)
}

test_input := `7,1
11,1
11,7
9,7
9,5
2,5
2,3
7,3`
