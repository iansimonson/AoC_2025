package day1

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

    fmt.println("Advent of Code Day 1!")
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
    fmt.wprintln(stderr, "Usage: day1 <path/to/input.txt>")
}

part_1 :: proc(data: string) -> int {
    zeros: int
    dial := 50
    data := data

    line_no: int
    for line in strings.split_lines_iterator(&data) {
        defer line_no += 1
        if len(line) == 0 do continue

        value, v_ok := strconv.parse_int(line[1:])
        if !v_ok {
            fmt.wprintfln(stderr, "Unable to parse value on line %d - %s", line_no, line)
            continue
        }

        if line[0] == 'R' {
            dial = (dial + value) %% 100
        } else if line[0] == 'L' {
            dial = (dial - value) %% 100
        } else {
            fmt.wprintfln(stderr, "Invalid instruction on line %d - %s", line_no, line)
            continue
        }

        if dial == 0 {
            zeros += 1
        }
    }

    return zeros
}

part_2 :: proc(data: string) -> int {
    zeros: int
    dial := 50
    data := data

    line_no: int
    for line in strings.split_lines_iterator(&data) {
        defer line_no += 1
        if len(line) == 0 do continue

        value, v_ok := strconv.parse_int(line[1:])
        if !v_ok {
            fmt.wprintfln(stderr, "Unable to parse value on line %d - %s", line_no, line)
            continue
        }

        full_rotations := value / 100
        zeros += full_rotations

        partial_rot := value - (full_rotations * 100)

        if line[0] == 'R' {
            dial_end := (dial + partial_rot) %% 100
            if dial_end < dial {
                zeros += 1
            }
            dial = dial_end
        } else if line[0] == 'L' {
            dial_end := (dial - partial_rot) %% 100
            if (dial != 0 && dial_end > dial) || dial_end == 0 {
                zeros += 1
            }
            dial = dial_end
        } else {
            fmt.wprintfln(stderr, "Invalid instruction on line %d - %s", line_no, line)
            continue
        }
    }

    return zeros
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 3)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 6)
}

@(test)
part_2_test_2 :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(other_example), 10)
}

// Copy the example input here
test_input := `L68
L30
R48
L5
R60
L55
L1
L99
R14
L82
`

other_example := `R1000
`