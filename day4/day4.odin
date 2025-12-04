package day4

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

    fmt.println("Advent of Code Day 4!")
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

num_adjacent :: proc(data: string, idx: int, offsets: []int) -> int {
    result: int
    for o in offsets {
        i := idx + o
        if i < 0 || i >= len(data) { continue }
        if data[i] == '@' { result += 1 }
    }
    return result
}

part_1 :: proc(data: string) -> int {
    result: int
    width := strings.index_byte(data, '\n') + 1
    offsets := [?]int{-width - 1, -width, -width + 1, -1, +1, width - 1, width, width + 1}

    for c, i in data {
        if c != '@' { continue }
        if num_adjacent(data, i, offsets[:]) < 4 { result += 1 }
    }
    return result
}

part_2 :: proc(data: string) -> int {
    result: int
    width := strings.index_byte(data, '\n') + 1
    offsets := [?]int{-width - 1, -width, -width + 1, -1, +1, width - 1, width, width + 1}
    data_cur, data_next := transmute([]u8) strings.clone(data), transmute([]u8) strings.clone(data)

    for {
        removed: int
        for c, i in data_cur {
            data_next[i] = c
            if c != '@' { continue }
            if num_adjacent(string(data_cur), i, offsets[:]) < 4 { 
                removed += 1
                data_next[i] = '.'
            }
        }
        result += removed
        data_cur, data_next = data_next, data_cur
        if removed == 0 { break }
    }
    return result
}

Dir :: enum {
    Top_Left,
    Up,
    Top_Right,
    Left,
    Right,
    Bottom_Left,
    Down,
    Bottom_Right,
}

@(test)
part_1_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_1(test_input), 13)
}

@(test)
part_2_test :: proc(t: ^testing.T) {
    testing.expect_value(t, part_2(test_input), 43)
}

test_input := `..@@.@@@@.
@@@.@.@.@@
@@@@@.@.@@
@.@@@@..@.
@@.@@@@.@@
.@@@@@@@.@
.@.@.@.@@@
@.@@@.@@@@
.@@@@@@@@.
@.@.@@@.@.`
