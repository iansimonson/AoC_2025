package day7

import "core:fmt"
import "core:math"
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

    fmt.println("Advent of Code Day 7!")
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
    result: int
    data := data
    columns := make([dynamic]int)
    start := strings.index_byte(data, 'S')
    append(&columns, start)
    row: int
    for line in strings.split_lines_iterator(&data) {
        if len(line) == 0 { continue }
        defer row += 1
        cur_columns := columns[:]
        assert(len(cur_columns) > 0)

        for column in cur_columns {
            if column < 0 || column >= len(line) {
                continue
            } else if line[column] == '^' {
                result += 1
                if columns[len(columns) - 1] != column - 1 {
                    // avoid duplicates
                    append(&columns, column - 1)
                }
                append(&columns, column + 1)
            } else {
                if len(columns) == len(cur_columns) || columns[len(columns) - 1] != column {
                    append(&columns, column)
                }
            }
        }
        remove_range(&columns, 0, len(cur_columns))
    }
    return result
}

part_2 :: proc(data: string) -> int {
    result: int
    data := data
    columns := make([dynamic]int)
    start := strings.index_byte(data, 'S')
    width := strings.index_byte(data, '\n')
    cur_rays_per_column := make([]int, width)
    next_rays_per_column := make([]int, width)
    cur_rays_per_column[start] = 1
    append(&columns, start)
    row: int
    for line in strings.split_lines_iterator(&data) {
        if len(line) == 0 { continue }
        defer row += 1
        cur_columns := columns[:]
        assert(len(cur_columns) > 0)
        slice.zero(next_rays_per_column)

        for column in cur_columns {
            if column < 0 || column >= len(line) {
                continue
            } else if line[column] == '^' {
                if columns[len(columns) - 1] != column - 1 {
                    // avoid duplicates
                    append(&columns, column - 1)
                }
                append(&columns, column + 1)
                rays := cur_rays_per_column[column]
                next_rays_per_column[column - 1] += rays
                next_rays_per_column[column + 1] += rays
            } else {
                if len(columns) == len(cur_columns) || columns[len(columns) - 1] != column {
                    append(&columns, column)
                }
                next_rays_per_column[column] += cur_rays_per_column[column]
            }
        }
        cur_rays_per_column, next_rays_per_column = next_rays_per_column, cur_rays_per_column
        remove_range(&columns, 0, len(cur_columns))
    }
    for r in cur_rays_per_column {
        result += r
    }
    return result
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 21)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 40)
}

test_input := `.......S.......
...............
.......^.......
...............
......^.^......
...............
.....^.^.^.....
...............
....^.^...^....
...............
...^.^...^.^...
...............
..^...^.....^..
...............
.^.^.^.^.^...^.
...............
`
