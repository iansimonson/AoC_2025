package day6

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

    fmt.println("Advent of Code Day 6!")
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
    values := make([dynamic][2]int, 0, 1000)
    defer delete(values)
    for line in strings.split_lines_iterator(&data) {
        if len(line) == 0 { continue }

        line := line
        column: int
        for v in strings.split_iterator(&line, " ") {
            if len(v) == 0 { continue }

            if v[0] == '+' {
                assert(column < len(values))
                result += values[column][0]
            } else if v[0] == '*' {
                assert(column < len(values))
                result += values[column][1]
            } else {
                value, value_ok := strconv.parse_int(v)
                if !value_ok {
                    fmt.wprintfln(stderr, "column %d - %s: could not parse value", column, v)
                    return 0
                }

                if column >= len(values) {
                    append(&values, [2]int{0, 1})
                }

                values[column][0] += value
                values[column][1] *= value
            }

            column += 1
        }
    }
    return result
}

part_2 :: proc(data: string) -> int {
    result: int
    data := data
    values := make([dynamic]int, 0, 1000)
    defer delete(values)
    first_line, _ := strings.split_lines_iterator(&data)
    for c in first_line {
        v: int
        if c != ' ' {
            v = int(c - '0')
        }
        append(&values, v)
    }

    last_line: string
    for line in strings.split_lines_iterator(&data) {
        if len(line) == 0 { continue }
        if line[0] == '+' || line[0] == '*' {
            last_line = line
            break
        }

        for c, i in line {
            if c != ' ' {
                values[i] = values[i] * 10 + int(c - '0')
            }
        }
    }
    for i := 0; i < len(last_line); /**/ {
        if last_line[i] == '+' {
            sub_result := values[i]
            i += 1
            for  i < len(values) && values[i] != 0 {
                sub_result += values[i]
                i += 1
            }
            result += sub_result
            i += 1 // skip the "emptpy column"
        } else if last_line[i] == '*' {
            sub_result := values[i]
            i += 1
            for  i < len(values) && values[i] != 0 {
                sub_result *= values[i]
                i += 1
            }
            result += sub_result
            i += 1 // skip the "emptpy column"
        } else {
            assert(false, "should only see ops")
        }
    }
    return result
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 4277556)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 3263827)
}

test_input := `123 328  51 64 
 45 64  387 23 
  6 98  215 314
*   +   *   +  
`

