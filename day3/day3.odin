package day3

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

    fmt.println("Advent of Code Day 3!")
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
    result: int

    for line in strings.split_lines_iterator(&data) {
        if len(line) == 0 { continue }
        line := strings.trim_space(line)
        tens_idx, ones_idx := -1, -1
        largest: u8 = '0'
        for i in 0..<(len(line) - 1) {
            if line[i] > largest {
                tens_idx = i
                largest = line[i]
            }
        }
        largest = '0'
        for i in (tens_idx + 1)..<len(line) {
            if line[i] > largest {
                ones_idx = i
                largest = line[i]
            }
        }

        joltage := as_int(line[tens_idx]) * 10 + as_int(line[ones_idx])
        // fmt.printfln("indicies (%d, %d) - value %d", tens_idx, ones_idx, joltage)
        result +=  joltage

    }
    return result
}

part_2 :: proc(data: string) -> int {
    data := data
    result: int

    for line in strings.split_lines_iterator(&data) {
        if len(line) == 0 { continue }
        line := strings.trim_space(line)
        batteries_needed := 12
        next_idx := -1
        joltage: int
        for batteries_needed > 0 {
            largest: u8 = '0'
            start_idx := next_idx
            for i in (start_idx + 1)..<(len(line) - (batteries_needed - 1)) {
                if line[i] > largest {
                    next_idx = i
                    largest = line[i]
                }
            }
            assert(next_idx != -1)
            joltage = joltage * 10 + as_int(largest)
            batteries_needed -= 1
        }
        // fmt.printfln("found joltage %d", joltage)
        result += joltage
    }
    return result
}

as_int :: proc(ascii: u8) -> int {
    assert(ascii >= '0' && ascii <= '9')
    return int(ascii - '0')
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 357)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 3121910778619)
}

test_input := `987654321111111
811111111111119
234234234234278
818181911112111`
