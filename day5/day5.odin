package day5

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

    fmt.println("Advent of Code Day 5!")
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

Range :: [2]int

part_1 :: proc(data: string) -> int {
    result: int

    parts, parts_err := strings.split(data, "\n\n")
    if parts_err != nil || (len(parts) != 2) { return 0 }

    range_strs := parts[0]
    ranges := make([dynamic]Range, 0, 100)
    for line in strings.split_lines_iterator(&range_strs) {
        split := strings.index_byte(line, '-')
        if split == -1 { return 0 }

        begin, b_ok := strconv.parse_int(line[:split])
        end, e_ok := strconv.parse_int(line[split+1:])
        if !b_ok || !e_ok { return 0 }

        append(&ranges, Range{begin, end})
    }

    value_strs := parts[1]
    for line in strings.split_lines_iterator(&value_strs) {
        id, id_ok := strconv.parse_int(line)
        if !id_ok { return 0 }
        for r in ranges {
            if id >= r[0] && id <= r[1] { 
                result += 1
                break
            }
        }
    }


    return result
}

part_2 :: proc(data: string) -> int {
    parts, parts_err := strings.split(data, "\n\n")
    if parts_err != nil || (len(parts) != 2) { return 0 }

    range_strs := parts[0]
    ranges := make([dynamic]Range, 0, 100)
    for line in strings.split_lines_iterator(&range_strs) {
        split := strings.index_byte(line, '-')
        if split == -1 { return 0 }

        begin, b_ok := strconv.parse_int(line[:split])
        end, e_ok := strconv.parse_int(line[split+1:])
        if !b_ok || !e_ok { return 0 }

        append(&ranges, Range{begin, end})
    }

    ranges_scratch := make([dynamic]Range, 0, len(ranges))
    ranges_cur := &ranges
    ranges_next := &ranges_scratch

    for {
        clear(ranges_next)
        for r in ranges_cur {
            merged: bool
            for &r2 in ranges_next {
                if r[1] < r2[0] || r[0] > r2[1] { continue }
                if r[0] <= r2[0] && r[1] >= r2[0] { // overlap left
                    r2[0] = min(r[0], r2[0])
                    r2[1] = max(r[1], r2[1])
                } else if r[0] <= r2[1] && r[1] >= r2[1] { // overlap right
                    r2[0] = min(r[0], r2[0])
                    r2[1] = max(r[1], r2[1])
                } else if r[0] >= r2[0] && r[1] <= r2[1] { // inside completely
                    r2 = r2
                } else if r[0] <= r2[0] && r[1] >= r2[1] { // completely envelops
                    r2 = r
                }
                merged = true
            }

            if !merged {
                append(ranges_next, r)
            }
        }
        if len(ranges_cur^) == len(ranges_next^) { break }
        ranges_cur, ranges_next = ranges_next, ranges_cur
    }

    result: int
    for r in ranges_cur {
        result += (r[1] - r[0] + 1) // inclusive ranges
    }
    return result
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 3)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 14)
}

test_input := `3-5
10-14
16-20
12-18

1
5
8
11
17
32`

